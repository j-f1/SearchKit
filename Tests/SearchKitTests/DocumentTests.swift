import XCTest
import SearchKit

final class DocumentTests: XCTestCase {
    func testDocumentFromURL() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let url = URL(string: "https://example.com")!
        guard let document = Document(url: url) else { return XCTFail("nil document") }
        XCTAssertEqual(document.url, url)
        XCTAssertEqual(document.scheme, "https")
        XCTAssertEqual(document.name, "example.com")
        XCTAssertNil(document.parent)
    }

    func testDocumentWithoutURL() throws {
        guard let document = Document(scheme: "test-suite", parent: nil, name: "hello, world") else { return XCTFail("nil document") }
        XCTAssertNil(document.url)
        XCTAssertEqual(document.scheme, "test-suite")
        XCTAssertEqual(document.name, "hello, world")
        XCTAssertNil(document.parent)
    }

    func testDocumentCFRepresentation() throws {
        let url = URL(string: "https://example.com")!
        guard let document = Document(url: url) else { return XCTFail("nil document") }
        XCTAssertEqual(CFGetTypeID(document.document), SKDocumentGetTypeID())
    }
}
