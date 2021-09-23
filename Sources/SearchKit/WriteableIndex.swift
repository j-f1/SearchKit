//
//  File.swift
//  
//
//  Created by Jed Fox on 9/23/21.
//

import Foundation

class WriteableIndex: Index {
    static func create(in fileURL: URL, name: String? = nil, type: SKIndexType, properties: [Index.AnalysisProperty]? = nil) -> WriteableIndex? {
        WriteableIndex(retained: SKIndexCreateWithURL(fileURL as CFURL, name as CFString?, type, properties?.dict))
    }

    static func create(data: NSMutableData, name: String? = nil, type: SKIndexType, properties: [Index.AnalysisProperty]? = nil) -> WriteableIndex? {
        WriteableIndex(retained: SKIndexCreateWithMutableData(data, name as CFString?, type, properties?.dict))
    }

    public static func open(data: NSMutableData, name: String? = nil) -> WriteableIndex? {
        WriteableIndex(retained: SKIndexOpenWithMutableData(data, name as CFString?))
    }

    public static func open(fileURL: URL, named name: String? = nil) -> WriteableIndex? {
        WriteableIndex(retained: SKIndexOpenWithURL(fileURL as CFURL, name as CFString?, true))
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
        internal let index: WriteableIndex
        internal init(index: WriteableIndex, document: SKDocument?) {
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

private extension Array where Element == SearchKit.Index.AnalysisProperty {
    var dict: CFDictionary {
        Dictionary(uniqueKeysWithValues: self.map(\.keyValuePair)) as CFDictionary
    }
}
