//
//  HughesAutoformersTool.swift
//
//
//  Created by Alsey Coleman Miller on 3/12/24.
//

import Foundation
import CoreFoundation
import Dispatch
import Bluetooth
import GATT
import ArgumentParser

@main
struct HughesAutoformersTool: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "A command line tool for interacting with Hughes Autoformers Bluetooth devices.",
        version: "1.0.0",
        subcommands: [
            ScanCommand.self
        ],
        defaultSubcommand: ScanCommand.self
    )
}
