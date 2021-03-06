//
//  Search.swift
//  
//
//  Created by Jed Fox on 9/23/21.
//

import CoreServices.SearchKit
import Foundation

public class Search {
    public let search: SKSearch
    internal let index: Index

    internal init(index: Index, query: String, options: Options = .default) {
        self.index = index
        self.search = SKSearchCreate(index.index, query as CFString, options.rawValue).takeRetainedValue()
    }

    public func cancel() {
        SKSearchCancel(search)
    }

    public typealias Match = (id: Document, score: Float)

    public func findMatches(maximumCount: Int, maximumTime: TimeInterval) -> (matches: [Match], hasMore: Bool) {
        let count = maximumCount == 0 ? index.documentCount : maximumCount
        var documentIDs = Array<SKDocumentID>(repeating: 0, count: count)
        var scores = Array<Float>(repeating: 0, count: count)
        var foundCount = 0
        let hasMore = SKSearchFindMatches(search, maximumCount, &documentIDs, &scores, maximumTime, &foundCount)
        return (
            matches: Array(zip(
                documentIDs.prefix(foundCount).map { BoundDocument(index: index, id: $0) },
                scores.prefix(foundCount)
            )),
            hasMore: hasMore
        )
    }

    public func findAll(maximumTime: TimeInterval = 0) -> [Match] {
        var done = false
        var matches = [Match]()
        while !done {
            let (newMatches, hasMore) = findMatches(maximumCount: 1000, maximumTime: maximumTime)
            matches.append(contentsOf: newMatches)
            done = !hasMore
        }
        return matches
    }
}

extension Search {
    public struct Options: OptionSet {
        public static let `default` = Options(kSKSearchOptionDefault)
        public static let noRelevanceScores = Options(kSKSearchOptionNoRelevanceScores)
        public static let spaceMeansOR = Options(kSKSearchOptionSpaceMeansOR)
        public static let findSimilar = Options(kSKSearchOptionFindSimilar)

        public let rawValue: SKSearchOptions
        public init(rawValue: SKSearchOptions) {
            self.rawValue = rawValue
        }
        private init(_ value: Int) {
            self.rawValue = SKSearchOptions(value)
        }
    }
}
