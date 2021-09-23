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
        self.init(retained: SKIndexOpenWithData(data as CFData, name as CFString?))
    }

    public convenience init?(url: URL, named name: String? = nil) {
        self.init(retained: SKIndexOpenWithURL(url as CFURL, name as CFString?, false))
    }

    internal init?(retained index: Unmanaged<SKIndex>?) {
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
