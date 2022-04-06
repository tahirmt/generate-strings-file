import ArgumentParser
import Rainbow
import Foundation
import PathKit
import Algorithms

struct Merge: ParsableCommand {
    // MARK: Properties

    static var configuration = CommandConfiguration(
        abstract: "Merge two strings files together by performing a union."
    )

    // MARK: Properties

    @Option(help: "The path to the source strings file.")
    var source: String

    @Option(help: "The path to the destination strings file")
    var destination: String = "./Localizable.strings"

    // MARK: Run

    func run() throws {
        let sourceString: String = try Path(source).read()
        let destinationString: String = try Path(destination).read()

        let sourceComponents = try sourceString.parseStringsFile()
        let destinationComponents = try destinationString.parseStringsFile()

        let merged = destinationComponents.merge(with: sourceComponents)

        let destinationPath = Path(destination)

        try destinationPath.write(merged.fileContents)
    }
}

extension Array where Element == StringsFileComponent {
    var fileContents: String {
        flatMap(\.lines).joined(separator: "\n")
    }

    /// Merge the other strings components into the soruce
    /// - Parameter other: Other strings file components to merge into self
    /// - Returns: a new array with merged keys and values
    func merge(with other: [Element]) -> [Element] {
        var output = self

        other.forEach { component in
            switch component {
            case let component as EmptyLine:
                // do not allow more than one empty line
                if output.last is EmptyLine {}
                else {
                    output.append(component)
                }
            case let component as LocalizableComponent:
                // match them based on values because when we generate them from code the key and value will be the same
                if let index = output.firstIndex(where: { ($0 as? LocalizableComponent)?.value == component.value }), let existingComponent = output[index] as? LocalizableComponent {
                    // check if the comment is the same
                    if !component.lines.isEmpty && existingComponent.lines.isEmpty {
                        // the old component didn't have any comments but the new one does. Add the new one but use the old key
                        output[index] = LocalizableComponent(key: existingComponent.key, value: component.value, comments: component.comments)
                    }
                } else {
                    output.append(component)
                }
            case let component as CommentLines:
                // stray comment lines should just be added as is
                output.append(component)
            default:
                print("Unhandled component \(type(of: component))".red)
            }
        }
        return output
    }
}
