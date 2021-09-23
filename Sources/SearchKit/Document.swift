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
        self.init(SKDocumentCreateWithURL(url as CFURL))
    }

    public convenience init?(scheme: String?, parent: Document? = nil, name: String) {
        self.init(SKDocumentCreate(scheme as CFString?, parent?.document, name as CFString))
    }

    private convenience init?(_ document: Unmanaged<SKDocument>?) {
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
