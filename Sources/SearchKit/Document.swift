//
//  Document.swift
//  
//
//  Created by Jed Fox on 9/22/21.
//

import CoreServices
import Foundation

class Document {
    let document: SKDocument

    public convenience init?(_ url: URL) {
        self.init(SKDocumentCreateWithURL(url as CFURL)?.takeRetainedValue())
    }

    public convenience init?(scheme: String?, parent: Document? = nil, name: String) {
        self.init(SKDocumentCreate(scheme as CFString?, parent?.document, name as CFString)?.takeRetainedValue())
    }

    private init?(_ document: SKDocument?) {
        if let document = document {
            self.document = document
        } else {
            return nil
        }
    }

    var url: URL? { SKDocumentCopyURL(document).takeRetainedValue() as URL? }
    var scheme: String? { SKDocumentGetSchemeName(document).takeUnretainedValue() as String? }
    var name: String? { SKDocumentGetName(document).takeUnretainedValue() as String? }
    var parent: Document? { Document(SKDocumentGetParent(document)?.takeUnretainedValue()) }
}
