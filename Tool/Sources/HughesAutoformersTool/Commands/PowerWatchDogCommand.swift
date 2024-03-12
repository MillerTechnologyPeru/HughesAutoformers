//
//  PowerWatchDogCommand.swift
//
//
//  Created by Alsey Coleman Miller on 3/12/24.
//

import Foundation
import Bluetooth
import GATT
import ArgumentParser
import HughesAutoformers

struct PowerWatchDogCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        commandName: "power-watchdog",
        abstract: "Connect to a Power Watchdog device and stream values."
    )
    
    @Option(help: "Identifier or address of Power Watchdog device.")
    var device: String
    
    @Option(help: "Coalesce multiple discoveries of the same peripheral into a single discovery event.")
    var filterDuplicates: Bool = false
    
    func run() async throws {
        let (connection, accessory) = try await connect(
            to: device,
            filterDuplicates: filterDuplicates,
            timeout: 5.0
        )
        let stream = try await connection.powerWatchdogStatus()
        for try await notification in stream {
            print("[\(connection.peripheral)] \(notification.voltage)V \(notification.amperage)A \(notification.watts)W \(notification.totalWatts)kWh")
        }
    }
}
