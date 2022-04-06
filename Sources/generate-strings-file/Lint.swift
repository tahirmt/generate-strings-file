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

struct Lint: ParsableCommand {
    // MARK: Properties

    static var configuration = CommandConfiguration(
        abstract: "Lint to validate strings file"
    )

    // MARK: Properties

    @Option(help: "The path to the source strings file.")
    var source: String

    // MARK: Run

    func run() throws {
        let sourceString: String = try Path(source).read()

        // just parsing the file
        _ = try sourceString.parseStringsFile()
    }
}
