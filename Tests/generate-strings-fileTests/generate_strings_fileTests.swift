import XCTest
@testable import generate_strings_file

final class generate_strings_fileTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        // XCTAssertEqual(generate_strings_file().text, "Hello, World!")
    }

    func testCamelCase() throws {
        let teststring = "hello_world_this_is_it"

        XCTAssertEqual(teststring.camelCased, "HelloWorldThisIsIt")
    }

    func testLowerCamelCase() throws {
        let teststring = "hello_world_this_is_it"

        XCTAssertEqual(teststring.lowerCamelCased, "helloWorldThisIsIt")
    }

    func testGeneratedVariable() throws {
        let component = LocalizableComponent(key: "first.second_world.third_hello_world.this_is_awesome", value: "hello", comments: [])

        XCTAssertEqual(component.generatedVariable, "L10n.First.SecondWorld.ThirdHelloWorld.thisIsAwesome")
    }
}
