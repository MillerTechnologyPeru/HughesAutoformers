//
//  ScanCommand.swift
//
//
//  Created by Alsey Coleman Miller on 3/12/24.
//

import Foundation
import Bluetooth
import GATT
import ArgumentParser
import HughesAutoformers

struct ScanCommand: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(abstract: "Scan for nearby devices.")
    
    @Option(help: "The scan duration.")
    var scanDuration: UInt = 5
    
    @Option(help: "Coalesce multiple discoveries of the same peripheral into a single discovery event.")
    var filterDuplicates: Bool = false
    
    func run() async throws {
        let central = try await loadBluetooth()
        #if canImport(CoreBluetooth)
        let stream = central.scan(
            with: [PowerWatchdog.service],
            filterDuplicates: filterDuplicates
        )
        #else
        let stream = try await central.scan(
            filterDuplicates: filterDuplicates
        )
        #endif
        Task {
            try? await Task.sleep(timeInterval: TimeInterval(scanDuration))
            stream.stop()
        }
        var peripherals = [NativeCentral.Peripheral: HughesAutoformersAccessory]()
        var scanResults = [NativeCentral.Peripheral: ScanDataCache<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
        for try await scanData in stream {
            let oldCacheValue = scanResults[scanData.peripheral]
            var cache = oldCacheValue ?? ScanDataCache(scanData: scanData)
            cache += scanData
            #if canImport(CoreBluetooth)
            for serviceUUID in scanData.advertisementData.overflowServiceUUIDs ?? [] {
                cache.overflowServiceUUIDs.insert(serviceUUID)
            }
            #endif
            scanResults[scanData.peripheral] = cache
            // try to parse
            guard peripherals[scanData.peripheral] == nil,
                  let advertisement = HughesAutoformersAccessory(scanData: cache) else {
                continue
            }
            peripherals[scanData.peripheral] = advertisement
            print("[\(scanData.peripheral)] \(advertisement.id)")
        }
    }
}
