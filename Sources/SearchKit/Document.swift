//
//  Document.swift
//  
//
//  Created by Jed Fox on 9/22/21.
//

import CoreServices
import Foundation

public class Document {
    public var document: SKDocument { storage }
    private let storage: SKDocument!
    internal init(_ document: SKDocument) {
        storage = document
    }
    fileprivate init() {
        storage = nil
    }

    public convenience init?(_ url: URL) {
        self.init(retained: SKDocumentCreateWithURL(url as CFURL))
    }

    public convenience init?(scheme: String?, parent: Document? = nil, name: String) {
        self.init(retained: SKDocumentCreate(scheme as CFString?, parent?.document, name as CFString))
    }

    internal convenience init?(retained document: Unmanaged<SKDocument>?) {
        if let document = document?.takeRetainedValue() {
            self.init(document)
        } else {
            return nil
        }
    }

    var url: URL? { SKDocumentCopyURL(document).takeRetainedValue() as URL? }
    var scheme: String? { SKDocumentGetSchemeName(document).takeUnretainedValue() as String? }
    var name: String? { SKDocumentGetName(document).takeUnretainedValue() as String? }
    var parent: Document? { (SKDocumentGetParent(document)?.takeUnretainedValue()).map(Document.init) }
}

public class BoundDocument: Document {
    internal let index: Index

    public override var document: SKDocument {
        get {
            switch storage {
            case .id(let id):
                let document = SKIndexCopyDocumentForDocumentID(index.index, id).takeRetainedValue()
                storage = .document(document)
                return document
            case .document(let document): return document
            }
        }
        set {}
    }

    private var storage: Storage
    private enum Storage {
        case id(SKDocumentID)
        case document(SKDocument)
    }

    internal init?(index: Index, retainedDocument document: Unmanaged<SKDocument>?) {
        self.index = index
        guard let document = document?.takeRetainedValue() else { return nil }
        self.storage = .document(document)
        super.init(document)
    }

    internal init(index: Index, id: SKDocumentID) {
        self.index = index
        self.storage = .id(id)
        super.init()
        self.id = id
    }

    public private(set) lazy var id = SKIndexGetDocumentID(index.index, document)

    public var terms: [Term] {
        (SKIndexCopyTermIDArrayForDocumentID(index.index, id).takeRetainedValue() as! [CFNumber]).map {
            Term(index: index, id: ($0 as NSNumber).intValue)
        }
    }

    public var properties: CFDictionary? {
        SKIndexCopyDocumentProperties(index.index, document)?.takeRetainedValue()
    }

    public var state: SKDocumentIndexState {
        SKIndexGetDocumentState(index.index, document)
    }

    public var termCount: Int {
        SKIndexGetDocumentTermCount(index.index, id)
    }

    public func numberOfOccurrences(of term: Term) -> Int {
        SKIndexGetDocumentTermFrequency(index.index, id, term.id)
    }
}

public class MutableBoundDocument: BoundDocument {
    internal let writableIndex: WriteableIndex

    internal init?(index: WriteableIndex, retainedDocument document: Unmanaged<SKDocument>?) {
        self.writableIndex = index
        super.init(index: index, retainedDocument: document)
    }

    internal init(index: WriteableIndex, id: SKDocumentID) {
        self.writableIndex = index
        super.init(index: index, id: id)
    }

    public override var name: String? {
        get { super.name }
        set { _ = writableIndex.rename(self, name: newValue!) }
    }

    public override var parent: Document? {
        get { super.parent }
        set { _ = writableIndex.move(self, to: newValue) }
    }

    public override var properties: CFDictionary? {
        get { super.properties }
        set { SKIndexSetDocumentProperties(index.index, document, newValue) }
    }

    public func removeFromIndex() -> Bool {
        writableIndex.remove(self)
    }
}
