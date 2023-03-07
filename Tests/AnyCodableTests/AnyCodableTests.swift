@testable import AnyCodable
import XCTest

class ComplexEntity: Codable, Equatable {
    let name: String
    let age: Double

    init(name: String, age: Double) {
        self.name = name
        self.age = age
    }

    static func == (lhs: ComplexEntity, rhs: ComplexEntity) -> Bool {
        lhs.age == rhs.age && lhs.name == rhs.name
    }
}

final class AnyCodableTests: XCTestCase {
    func testBasicWrapping() throws {
        let value = AnyCodable("Hello World")
        XCTAssertEqual(value.base as? String, "Hello World")
    }

    func testEncodingDecoding() throws {
        let encoder = JSONEncoder()
        let entity = ComplexEntity(name: "John Appleseed", age: 50)
        let wrappedValue = AnyCodable(entity)
        let data = try encoder.encode(wrappedValue)

        let decoder = JSONDecoder()
        let decodedValue = try decoder.decode(AnyCodable.self, from: data)
        XCTAssertEqual(decodedValue.base as? ComplexEntity, entity)
    }

    func testPostponingEncodingError() throws {
        let encoder = JSONEncoder()
        let entity = ComplexEntity(name: "John Appleseed", age: .infinity)
        let wrappedValue = AnyCodable(entity)

        XCTAssertThrowsError(try encoder.encode(wrappedValue))
    }

    func testEquality() throws {
        let value = AnyCodable("Hello World")
        let otherValue = AnyCodable("Hello World")
        let neitherValue = AnyCodable("Hello?")

        XCTAssertEqual(value, otherValue)
        XCTAssertNotEqual(value, neitherValue)
    }
}
