import ArgumentParser
import Rainbow
import Foundation
import PathKit
import Algorithms

@main
struct Main: ParsableCommand {
    // MARK: Properties

    static var configuration = CommandConfiguration(
        abstract: "Generate the strings file from a Swift source code."
    )

    // MARK: Properties

    @Option(help: "The path to the source code.")
    var source: String = "."

    @Option(help: "The path to the Localizable.strings file. Defaults to the file in the same directory")
    var output: String = "./Localizable.strings"

    @Option(help: "Comma separated file types. Defaults to swift and objective c m file")
    var fileTypes: String = "swift,m"

    @Option(help: "Comma separated excluded directories relative to the source directory. Defaults to .build")
    var excludedDirectories: String = ".build"

    // MARK: Run

    func run() throws {
        let path = Path(source)

        let allFileTypes = fileTypes
            .replacingOccurrences(of: " ", with: "")
            .components(separatedBy: ",")
            .map { $0.lowercased() }

        let allExcludedDirectories = excludedDirectories
            .replacingOccurrences(of: " ", with: "")
            .components(separatedBy: ",")

        let allChildren = try path.recursiveChildren()
            .filter { childPath in
                guard let ext = childPath.`extension` else {
                    return false
                }

                let matchingFiltType = allFileTypes.contains(ext)

                let excluded = allExcludedDirectories.contains { directory in
                    childPath.string.hasPrefix(directory)
                }

                return matchingFiltType && !excluded
            }

        let localizableStrings: [[Localizable]] = try allChildren.compactMap { childPath in
            let contents = try Data(contentsOf: childPath.url)
            let stringValue = String(data: contents, encoding: .utf8)

            return try stringValue?.extractLocalizableStrings() ?? []
        }

        let allLocalizables = localizableStrings.flatMap { $0 }
        print("Found localizable \(allLocalizables.count) strings".green)

        // generate the contents of the localizable file
        var fileLines: [String] = []

        allLocalizables.uniqued(on: \.key).forEach { localizable in
            if let comment = localizable.comment, !comment.isEmpty {
                fileLines.append("// \(comment)")
            }

            fileLines.append("\"\(localizable.key)\" = \"\(localizable.key)\";")
        }

        let contents = fileLines.joined(separator: "\n")

        let outputPath = Path(output)
        try outputPath.write(contents)
    }
}

struct Localizable {
    let key: String
    let comment: String?
}


private extension String {
    func extractLocalizableStrings() throws -> [Localizable] {
        let patterns: [NSRegularExpression] = [
            // swift
            try NSRegularExpression(pattern: "NSLocalizedString\\(\"(.*)\", comment: \"(.*)\"\\)", options: []),
            // objc
            try NSRegularExpression(pattern: "NSLocalizedString\\(@\"(.*)\", @\"(.*)\"\\)", options: []),
            try NSRegularExpression(pattern: "NSLocalizedString\\(@\"(.*)\", nil\\)", options: []),
        ]

        let matches: [NSTextCheckingResult] = patterns.flatMap { pattern in
            pattern.matches(in: self, range: NSRange(location: 0, length: self.count))
        }

        let localizables: [Localizable] = matches.map { match in
            let keyRange = match.range(at: 1)
            let key = (self as NSString).substring(with: keyRange)

            let comment: String?
            if match.numberOfRanges > 2 {
                let commentRange = match.range(at: 2)
                comment = (self as NSString).substring(with: commentRange)
            } else {
                comment = nil
            }

            return Localizable(key: key, comment: comment)
        }

        return localizables
    }
}
