//
//  Index.swift
//  
//
//  Created by Jed Fox on 9/22/21.
//

import CoreServices
import Foundation

public extension SKIndexType {
    /// Specifies an unknown index type.
    static let unknown = kSKIndexUnknown

    /// Specifies an inverted index, mapping terms to documents.
    static let inverted = kSKIndexInverted

    /// Vector index, mapping documents to terms.
    static let vector = kSKIndexVector

    /// Index type with all the capabilities of an inverted and a vector index.
    static let invertedVector = kSKIndexInvertedVector
}

class Index {
    public let index: SKIndex

    public private(set) lazy var type = SKIndexGetIndexType(index)

    public convenience init?(data: Data, named name: String? = nil) {
        self.init(SKIndexOpenWithData(data as CFData, name as CFString?))
    }

    public convenience init?(url: URL, named name: String? = nil) {
        self.init(SKIndexOpenWithURL(url as CFURL, name as CFString?, false))
    }

    fileprivate init?(_ index: Unmanaged<SKIndex>?) {
        if let index = index {
            self.index = index.takeRetainedValue()
        } else {
            return nil
        }
    }

    deinit {
        SKIndexClose(index)
    }

    public var documentCount: Int { SKIndexGetDocumentCount(index) }
    public var maxDocumentID: Int { SKIndexGetMaximumDocumentID(index) }
    public var maxTermID: Int { SKIndexGetMaximumTermID(index) }

    public func children(of document: Document) -> DocumentIterator {
        DocumentIterator(index: self, document: document.document)
    }

    public var rootDocuments: DocumentIterator {
        DocumentIterator(index: self, document: nil)
    }

    public class DocumentIterator: IteratorProtocol {
        internal let iterator: SKIndexDocumentIterator
        internal init(index: Index, document: SKDocument?) {
            self.iterator = SKIndexDocumentIteratorCreate(index.index, document).takeRetainedValue()
        }

        public func next() -> Document? {
            (SKIndexDocumentIteratorCopyNext(iterator)?.takeRetainedValue()).map(Document.init)
        }
    }

    public var analysisProperties: [AnalysisProperty] {
        (SKIndexGetAnalysisProperties(index).takeUnretainedValue() as! [CFString: AnyObject]).compactMap(AnalysisProperty.init)
    }
}

public class BoundDocument: Document {
    internal let index: Index.Writeable

    init(index: Index.Writeable, document: SKDocument) {
        self.index = index
        super.init(document)
    }

    public override var name: String? {
        get { super.name }
        set { _ = index.rename(self, name: newValue!) }
    }

    public override var parent: Document? {
        get { super.parent }
        set { _ = index.move(self, to: newValue) }
    }

    public func removeFromIndex() -> Bool {
        index.remove(self)
    }
}

extension Index {
    public enum AnalysisProperty {
        // default: 1
        case minTermLength(Int)

        // default: []
        case stopWords(Set<String>)

        // default: ???
        case substitutions([String: String])

        // default: 2000; specify 0 for no limit
        case maxTerms(Int)

        // default: false; only applies to inverted indices
        case proximityIndexing(Bool)

        // additional characters to allow within a term/word
        case termCharacters(String)

        // overrides .termCharacters for the first character of a term/word
        case startTermCharacters(String)

        // overrides .termCharacters for the last character of a term/word
        case endTermCharacters(String)

        case __unknown(CFString, AnyObject)

        internal init(key: CFString, value: AnyObject) {
            if key == kSKMinTermLength, let length = value as? Int {
                self = .minTermLength(length)
            } else if key == kSKStopWords, let words = value as? Set<String> {
                self = .stopWords(words)
            } else if key == kSKSubstitutions, let substitutions = value as? [String: String] {
                self = .substitutions(substitutions)
            } else if key == kSKMaximumTerms, let maxTerms = value as? Int {
                self = .maxTerms(maxTerms)
            } else if key == kSKProximityIndexing, let isEnabled = value as? Bool {
                self = .proximityIndexing(isEnabled)
            } else if key == kSKTermChars, let chars = value as? String {
                self = .termCharacters(chars)
            } else if key == kSKStartTermChars, let chars = value as? String {
                self = .startTermCharacters(chars)
            } else if key == kSKEndTermChars, let chars = value as? String {
                self = .endTermCharacters(chars)
            } else {
                self = .__unknown(key, value)
            }
        }

        internal var keyValuePair: (CFString, AnyObject) {
            switch self {
            case .minTermLength(let length):
                return (kSKMinTermLength, length as CFNumber)
            case .stopWords(let stopWords):
                return (kSKStopWords, stopWords as CFSet)
            case .substitutions(let substitutions):
                return (kSKSubstitutions, substitutions as CFDictionary)
            case .maxTerms(let maxTerms):
                return (kSKMaximumTerms, maxTerms as CFNumber)
            case .proximityIndexing(let isEnabled):
                return (kSKProximityIndexing, isEnabled as CFBoolean)
            case .termCharacters(let chars):
                return (kSKTermChars, chars as CFString)
            case .startTermCharacters(let chars):
                return (kSKStartTermChars, chars as CFString)
            case .endTermCharacters(let chars):
                return (kSKEndTermChars, chars as CFString)
            case .__unknown(let key, let value):
                return (key, value)
            }
        }
    }
}

private extension Array where Element == SearchKit.Index.AnalysisProperty {
    var dict: CFDictionary {
        Dictionary(uniqueKeysWithValues: self.map(\.keyValuePair)) as CFDictionary
    }
}

extension Index {
    class Writeable: Index {
        static func create(in fileURL: URL, name: String? = nil, type: SKIndexType, properties: [Index.AnalysisProperty]? = nil) -> Index.Writeable? {
            Index.Writeable(SKIndexCreateWithURL(fileURL as CFURL, name as CFString?, type, properties?.dict))
        }

        static func create(data: NSMutableData, name: String? = nil, type: SKIndexType, properties: [Index.AnalysisProperty]? = nil) -> Index.Writeable? {
            Index.Writeable(SKIndexCreateWithMutableData(data, name as CFString?, type, properties?.dict))
        }

        public static func open(data: NSMutableData, name: String? = nil) -> Index.Writeable? {
            Index.Writeable(SKIndexOpenWithMutableData(data, name as CFString?))
        }

        public static func open(fileURL: URL, named name: String? = nil) -> Index.Writeable? {
            Index.Writeable(SKIndexOpenWithURL(fileURL as CFURL, name as CFString?, true))
        }

        public func add(_ document: Document, text: String?, overwrite: Bool) -> Bool {
            SKIndexAddDocumentWithText(index, document.document, text as CFString?, overwrite)
        }

        public func add(fileDocument document: Document, mimeTypeHint: String? = nil, overwrite: Bool) -> Bool {
            SKIndexAddDocument(index, document.document, mimeTypeHint as CFString?, overwrite)
        }

        public func flush() {
            SKIndexFlush(index)
        }

        /// Do not call this method on the main thread in an application with a user interface.
        /// Call it only if the index is significantly fragmented and according to the needs of your application.
        /// Close all clients of the index before calling this method.
        public func compact() {
            SKIndexCompact(index)
        }


        public func move(_ document: Document, to newParent: Document?) -> Bool {
            SKIndexMoveDocument(index, document.document, newParent?.document)
        }

        public func remove(_ document: Document) -> Bool {
            SKIndexRemoveDocument(index, document)
        }

        public func rename(_ document: Document, name: String) -> Bool {
            SKIndexRenameDocument(index, document.document, name as CFString)
        }

        @available(*, deprecated)
        public var maxBytesBeforeFlush: Int {
            get { SKIndexGetMaximumBytesBeforeFlush(index) }
            set { SKIndexSetMaximumBytesBeforeFlush(index, newValue) }
        }

        public override func children(of document: Document) -> DocumentIterator {
            DocumentIterator(index: self, document: document.document)
        }

        public override var rootDocuments: DocumentIterator {
            DocumentIterator(index: self, document: nil)
        }

        public class DocumentIterator: Index.DocumentIterator {
            internal let index: Index.Writeable
            internal init(index: Index.Writeable, document: SKDocument?) {
                self.index = index
                super.init(index: index, document: document)
            }

            public override func next() -> BoundDocument? {
                if let document = SKIndexDocumentIteratorCopyNext(iterator)?.takeRetainedValue() {
                    return BoundDocument(index: index, document: document)
                } else {
                    return nil
                }
            }
        }
    }
}
