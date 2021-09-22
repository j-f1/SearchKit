import CoreServices
import Foundation

public class Summary {
    public let summary: SKSummary
    init(_ string: String) {
        summary = SKSummaryCreateWithString(string as NSString).takeRetainedValue()
    }

    func summarize(maxSentences: Int) -> String {
        SKSummaryCopySentenceSummaryString(summary, maxSentences).takeRetainedValue() as String
    }

    func summarize(maxParagraphs: Int) -> String {
        SKSummaryCopyParagraphSummaryString(summary, maxParagraphs).takeRetainedValue() as String
    }

    public var sentenceCount: CFIndex { SKSummaryGetSentenceCount(summary) }

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

        public var content: String {
            SKSummaryCopySentenceAtIndex(summary.summary, index).takeRetainedValue() as String
        }

        public var paragraph: Paragraph {
            summary.paragraphs[paragraphIndex]
        }
    }

    public private(set) lazy var paragraphs: [Paragraph] = {
        var rankOrders = Array<CFIndex>(repeating: 0, count: sentenceCount)
        var paragraphIndices = Array<CFIndex>(repeating: 0, count: sentenceCount)
        SKSummaryGetParagraphSummaryInfo(summary, sentenceCount, &rankOrders, &paragraphIndices)
        return rankOrders.enumerated().map {
            Paragraph(rankOrder: $0.element, index: paragraphIndices[$0.offset], summary: self)
        }
    }()

    public struct Paragraph {
        /// 1 for the most important paragraph
        public let rankOrder: CFIndex
        let index: CFIndex
        unowned let summary: Summary

        public var content: String {
            SKSummaryCopyParagraphAtIndex(summary.summary, index).takeRetainedValue() as String
        }
    }
}
