import ArgumentParser
import Rainbow
import Foundation
import PathKit
import Algorithms

struct Sort: ParsableCommand {
    // MARK: Properties

    static var configuration = CommandConfiguration(
        abstract: "Sort a localizable string keys by keys"
    )

    // MARK: Properties

    @Option(help: "The path to the source strings file.")
    var source: String

    // MARK: Run

    func run() throws {
        // extract localizable strings from the strings file
        let sourceString: String = try Path(source).read()

        // just parsing the file
        let components = try sourceString.parseStringsFile()

        var allComponents: [ComponentWithSpacers] = []

        // group the spacers with file components
        var spacers: [EmptyLine] = []
        var commentLine: CommentLines?

        components.forEach {
            if let spacer = $0 as? EmptyLine {
                spacers.append(spacer)
            }
            else if let comment = $0 as? CommentLines {
                commentLine = comment
            } else if let localizable = $0 as? LocalizableComponent {
                let component = ComponentWithSpacers(
                    spacers: spacers,
                    comments: commentLine,
                    string: localizable)

                allComponents.append(component)

                spacers.removeAll()
                commentLine = nil
            }
        }

        // components are done. Now we can sort

        let sortedComponents = allComponents.sorted { $0.string.key < $1.string.key }

        // write it back to the file

        let contents = sortedComponents.flatMap(\.lines).joined(separator: "\n")

        let outputPath = Path(source)
        try outputPath.write(contents)
    }
}

private struct ComponentWithSpacers: StringsFileComponent {
    let spacers: [EmptyLine]
    let comments: CommentLines?
    let string: LocalizableComponent

    var lines: [String] {
        spacers.flatMap(\.lines) + (comments?.lines ?? []) + string.lines
    }
}
