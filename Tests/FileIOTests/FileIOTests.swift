import XCTest
@testable import FileIO

class FileIOTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(FileIO().text, "Hello, World!")
    }


    static var allTests : [(String, (FileIOTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
