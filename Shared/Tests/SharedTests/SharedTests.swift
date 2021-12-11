import XCTest
@testable import Shared

final class SharedTests: XCTestCase {
    func testExample() throws {
        let inputDate = "2021-12-11T15:42:30Z"
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.timeZone = .init(secondsFromGMT: 0)
        let parsedDate = isoFormatter.date(from: inputDate)!
        print(parsedDate)
        let f = ConfigParser.dateFormatter
        f.timeZone = .init(secondsFromGMT: 0)
        XCTAssertEqual(f.string(from: parsedDate), "2021-12-11T15:42:30")
    }
}
