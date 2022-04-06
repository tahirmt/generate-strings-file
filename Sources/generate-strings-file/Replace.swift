//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2022-04-06.
//

import ArgumentParser
import Rainbow
import Foundation
import PathKit
import Algorithms

struct Replace: ParsableCommand {
    // MARK: Properties

    static var configuration = CommandConfiguration(
        abstract: "Replace the strings in swift files for SwiftGen generated file"
    )

    // MARK: Properties

    @Option(help: "The path to the source code.")
    var source: String = "."

    @Option(help: "The path to the Localizable.strings file. Defaults to the file in the same directory")
    var stringsFilePath: String = "./Localizable.strings"

    @Option(help: "Comma separated file types. Defaults to swift and objective c m file")
    var fileTypes: String = "swift"

    @Option(help: "Comma separated excluded directories relative to the source directory. Defaults to .build")
    var excludedDirectories: String = ".build"

    @Option(help: "The module where all localizable files are stored. If passed the import will be added if needed")
    var localizableModule: String?

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

        // extract localizable strings from the strings file
        let sourceString: String = try Path(stringsFilePath).read()
        // just parsing the file
        let components = try sourceString.parseStringsFile()
            .compactMap { $0 as? LocalizableComponent }

        // find all localized strings in files
        try allChildren.forEach { childPath in
            var skippedKeys: [String] = []
            let stringValue: String = try childPath.read()

            var destinationString = stringValue
            var needsWrite = false

            let expression = try NSRegularExpression(pattern: "NSLocalizedString\\([ \n\t]*\"(.*)\",[ \n\t]*comment: \"(.*)\"[ \n\t]*\\)")

            while let match = expression.matches(in: destinationString, range: NSRange(location: 0, length: destinationString.count)).first(where: { match in
                // replace the contents of the match with a generated string
                let keyRange = match.range(at: 1)
                let key = (stringValue as NSString).substring(with: keyRange)

                return !skippedKeys.contains(key)
            }) {

                // replace the contents of the match with a generated string
                let keyRange = match.range(at: 1)
                let key = (stringValue as NSString).substring(with: keyRange)

                // find the key in localizable file
                if let localizable = components.first(where: {
                    $0.value == key
                }) {
                    // found the key in localizable. Replace the contents in the swift string
                    destinationString = (destinationString as NSString).replacingCharacters(in: match.range, with: localizable.generatedVariable)
                    needsWrite = true
                } else {
                    print("Key: \(key) not found".red)
                    skippedKeys.append(key)
                }
            }

            if needsWrite {
                if let localizableModule = localizableModule {
                    // check all imports
                    let importedModules = try destinationString.importedModules()
                    if !importedModules.contains(localizableModule) {
                        // import needs to be added
                        let allModules = importedModules + [localizableModule]
                        let sorted = allModules.sorted()

                        // check the index of the module name before localizable module
                        if let index = sorted.firstIndex(of: localizableModule) {
                            let targetIndex = index - 1

                            if targetIndex < 0 {
                                destinationString = try destinationString.insertImport(for: localizableModule, below: nil)
                            } else {
                                destinationString = try destinationString.insertImport(for: localizableModule, below: sorted[targetIndex])
                            }
                        }
                    }
                }

                try childPath.write(destinationString as String)
            }
        }
    }
}

private extension String {
    func importedModules() throws -> [String] {
        let expression = try NSRegularExpression(pattern: "import ([a-zA-Z]+)")

        let matches = expression.matches(in: self, range: NSRange(location: 0, length: count))

        return matches.map { match in
            (self as NSString).substring(with: match.range(at: 1))
        }
    }

    func insertImport(for moduleName: String, below otherModule: String?) throws -> String {
        let expression: NSRegularExpression

        if let otherModule = otherModule {
            expression = try NSRegularExpression(pattern: "import \(otherModule)")
        }
        else {
            expression = try NSRegularExpression(pattern: "import ([a-zA-Z]+)")
        }

        let matches = expression.matches(in: self, range: NSRange(location: 0, length: count))

        if let otherModule = otherModule {
            if let match = matches.last {
                return (self as NSString).replacingCharacters(in: match.range, with: "import \(otherModule)\nimport \(moduleName)")
            }
        } else {
            if let match = matches.first {
                let other = (self as NSString).substring(with: match.range(at: 1))
                return (self as NSString).replacingCharacters(in: match.range, with: "import \(moduleName)\nimport \(other)")
            }
        }

        return self
    }
}

extension LocalizableComponent {
    var generatedVariable: String {
        // each period denotes a new type generation. Except the last one which denotes a variable in lower camel case
        let keyComponents = key.components(separatedBy: ".")

        let typePath = keyComponents
            .enumerated()
            .map {
                $0.offset == keyComponents.count-1 ? $0.element.lowerCamelCased : $0.element.camelCased
            }
            .joined(separator: ".")

        return "L10n.\(typePath)"
    }
}

extension String {
    var camelCased: String {
        components(separatedBy: "_")
            .map { $0.capitalized }
            .joined(separator: "")
    }

    var lowerCamelCased: String {
        components(separatedBy: "_")
            .enumerated()
            .map { $0.offset == 0 ? $0.element.lowercased() : $0.element.capitalized }
            .joined(separator: "")
    }
}
