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
    internal let index: SKIndex

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
}

extension Index {
    class Writeable: Index {
        // TODO: `analysisProperties`
        static func create(in fileURL: URL, name: String? = nil, type: SKIndexType) -> Index.Writeable? {
            Index.Writeable(SKIndexCreateWithURL(fileURL as CFURL, name as CFString?, type, nil))
        }

        // TODO: `analysisProperties`
        static func create(data: NSMutableData, name: String? = nil, type: SKIndexType) -> Index.Writeable? {
            Index.Writeable(SKIndexCreateWithMutableData(data, name as CFString?, type, nil))
        }

        // TODO: `analysisProperties`
        public static func open(data: NSMutableData, name: String? = nil, type: SKIndexType) -> Index.Writeable? {
            Index.Writeable(SKIndexCreateWithMutableData(data, name as CFString?, type, nil))
        }

        // TODO: `analysisProperties`
        public static func open(fileURL: URL, named name: String? = nil) -> Index.Writeable? {
            Index.Writeable(SKIndexOpenWithURL(fileURL as CFURL, name as CFString?, true))
        }
    }
}
