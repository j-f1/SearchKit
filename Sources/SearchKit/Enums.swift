//
//  Enums.swift
//  SearchKit
//
//  Created by Jed Fox on 9/23/21.
//

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

public extension SKDocumentIndexState {
    /// Specifies that the document is not indexed.
    static let notIndexed = kSKDocumentStateNotIndexed

    /// Specifies that the document is indexed.
    static let indexed = kSKDocumentStateNotIndexed

    /// Specifies that the document is not in the index but will be added after the index is flushed or closed.
    static let addPending = kSKDocumentStateNotIndexed

    /// Specifies that the document is in the index but will be deleted after the index is flushed or closed.
    static let deletePending = kSKDocumentStateNotIndexed
}
