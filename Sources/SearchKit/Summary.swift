import CoreServices.SearchKit
import Foundation

public class Summary {
    public let summary: SKSummary
    public init(_ string: String) {
        summary = SKSummaryCreateWithString(string as NSString).takeRetainedValue()
    }

    public func summarize(maxSentences: Int) -> String {
        SKSummaryCopySentenceSummaryString(summary, maxSentences).takeRetainedValue() as String
    }

    public func summarize(maxParagraphs: Int) -> String {
        SKSummaryCopyParagraphSummaryString(summary, maxParagraphs).takeRetainedValue() as String
    }

    public private(set) lazy var sentenceCount: Int = SKSummaryGetSentenceCount(summary)

    public private(set) lazy var sentences: [Sentence] = {
        var rankOrders = Array<CFIndex>(repeating: 0, count: sentenceCount)
        var sentenceIndices = Array<CFIndex>(repeating: 0, count: sentenceCount)
        var paragraphIndices = Array<CFIndex>(repeating: 0, count: sentenceCount)
        SKSummaryGetSentenceSummaryInfo(summary, sentenceCount, &rankOrders, &sentenceIndices, &paragraphIndices)
        return rankOrders.enumerated().map {
            Sentence(
                rankOrder: $0.element,
                index: sentenceIndices[$0.offset],
                paragraphIndex: paragraphIndices[$0.offset],
                summary: self
            )
        }
    }()

    public struct Sentence {
        /// 1 for the most important sentence
        public let rankOrder: CFIndex
        let index: CFIndex
        let paragraphIndex: CFIndex
        unowned let summary: Summary

        public private(set) lazy var content = SKSummaryCopySentenceAtIndex(summary.summary, index).takeRetainedValue() as String
        public private(set) lazy var paragraph = summary.paragraphs[paragraphIndex]
    }

    public private(set) lazy var paragraphCount: Int = SKSummaryGetParagraphCount(summary)
    public private(set) lazy var paragraphs: [Paragraph] = {
        var rankOrders = Array<CFIndex>(repeating: 0, count: paragraphCount)
        var paragraphIndices = Array<CFIndex>(repeating: 0, count: paragraphCount)
        SKSummaryGetParagraphSummaryInfo(summary, paragraphCount, &rankOrders, &paragraphIndices)
        return rankOrders.enumerated().map {
            Paragraph(rankOrder: $0.element, index: paragraphIndices[$0.offset], summary: self)
        }
    }()

    public struct Paragraph {
        /// 1 for the most important paragraph
        public let rankOrder: CFIndex
        let index: CFIndex
        unowned let summary: Summary

        public private(set) lazy var content = SKSummaryCopyParagraphAtIndex(summary.summary, index).takeRetainedValue() as String
    }
}
