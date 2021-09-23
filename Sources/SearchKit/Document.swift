//
//  Document.swift
//  
//
//  Created by Jed Fox on 9/22/21.
//

import CoreServices
import Foundation

public class Document {
    public let document: SKDocument

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

    internal init(_ document: SKDocument) {
        self.document = document
    }

    var url: URL? { SKDocumentCopyURL(document).takeRetainedValue() as URL? }
    var scheme: String? { SKDocumentGetSchemeName(document).takeUnretainedValue() as String? }
    var name: String? { SKDocumentGetName(document).takeUnretainedValue() as String? }
    var parent: Document? { (SKDocumentGetParent(document)?.takeUnretainedValue()).map(Document.init) }
}

public class BoundDocument: Document {
    internal let index: WriteableIndex

    init(index: WriteableIndex, document: SKDocument) {
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
