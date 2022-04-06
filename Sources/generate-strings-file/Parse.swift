//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2022-04-06.
//

import Foundation

protocol StringsFileComponent {
    var lines: [String] { get }
}

struct EmptyLine: StringsFileComponent {
    var lines: [String] {
        [""]
    }
}

struct CommentLines: StringsFileComponent {
    let comments: [String]

    var lines: [String] {
        comments
    }
}

struct LocalizableComponent: StringsFileComponent {
    let key: String
    let value: String
    let comments: [String]

    var lines: [String] {
        comments + ["\"\(key)\" = \"\(value)\";"]
    }
}

extension String {
    func parseStringsFile() throws -> [StringsFileComponent] {
        let lines = components(separatedBy: .newlines)

        var components: [StringsFileComponent] = []
        var currentComments: [String] = []

        try lines.forEach { line in
            if line.isEmpty {
                if !currentComments.isEmpty {
                    // there are stray comments
                    components.append(CommentLines(comments: currentComments))
                    currentComments.removeAll()
                }

                components.append(EmptyLine())
            } else if line.isCommentLine {
                currentComments.append(line)
            } else {
                // parse key and value
                let pattern = try NSRegularExpression(pattern: "\"(.*)\" = \"(.*)\";", options: [])
                let matches = pattern.matches(in: line, range: NSRange(location: 0, length: line.count))

                if matches.isEmpty {
                    print("invalid line \(line)".red)
                }

                matches.forEach { match in
                    let keyRange = match.range(at: 1)
                    let key = (line as NSString).substring(with: keyRange)

                    let valueRange = match.range(at: 2)
                    let value = (line as NSString).substring(with: valueRange)

                    let stringComponent = LocalizableComponent(key: key, value: value, comments: currentComments)

                    components.append(stringComponent)
                }

                currentComments.removeAll()
            }
        }

        if !currentComments.isEmpty {
            // there are stray comments
            components.append(CommentLines(comments: currentComments))
            currentComments.removeAll()
        }

        return components
    }

    private var isCommentLine: Bool {
        hasPrefix("//")
    }
}
