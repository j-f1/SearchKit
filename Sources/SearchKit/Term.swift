//
//  Term.swift
//  SearchKit
//
//  Created by Jed Fox on 9/23/21.
//

import CoreServices.SearchKit

public struct Term {
    public let index: Index
    public let id: CFIndex
    public private(set) lazy var value = {
        SKIndexCopyTermStringForTermID(index.index, id).takeRetainedValue() as String
    }()

    public init(index: Index, id: CFIndex) {
        self.index = index
        self.id = id
    }

    public init?(index: Index, value: String) {
        self.index = index
        self.id = SKIndexGetTermIDForTermString(index.index, value as CFString)
        self.value = value

        guard id != kCFNotFound else { return nil }
    }
}
