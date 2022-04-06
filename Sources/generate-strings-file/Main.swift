//
//  File.swift
//  
//
//  Created by Mahmood Tahir on 2022-04-05.
//

import ArgumentParser
import Foundation

@main
struct Main: ParsableCommand {
    static var configuration = CommandConfiguration(
        subcommands: [
            Generate.self,
            Merge.self,
        ],
        defaultSubcommand: Generate.self
    )
}
