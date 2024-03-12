//
//  HughesAutoformersAccessory.swift
//  
//
//  Created by Alsey Coleman Miller on 3/12/24.
//

import Foundation
import Bluetooth
import GATT
import HughesAutoformers
import ArgumentParser

internal extension HughesAutoformersAccessory {
    
    init?(scanData: ScanDataCache<NativeCentral.Peripheral, NativeCentral.Advertisement>) {
        if let powerWatchdog = PowerWatchdog(scanData: scanData) {
            self = .powerWatchdog(powerWatchdog)
        } else {
            return nil
        }
    }
}

internal extension AsyncParsableCommand {
    
    func connect(
        to device: HughesAutoformersAccessory.ID,
        filterDuplicates: Bool,
        timeout: TimeInterval = 5.0
    ) async throws -> (connection: GATTConnection<NativeCentral>, accessory: HughesAutoformersAccessory) {
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
        var peripherals = [NativeCentral.Peripheral: HughesAutoformersAccessory]()
        var scanResults = [NativeCentral.Peripheral: ScanDataCache<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
        var foundAccessory: (peripheral: NativeCentral.Peripheral, accessory: HughesAutoformersAccessory)?
        let timeoutTask = Task {
            try? await Task.sleep(timeInterval: timeout)
            stream.stop()
        }
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
            guard advertisement.id == device || scanData.peripheral.id.description == device else {
                continue
            }
            stream.stop()
            timeoutTask.cancel()
            foundAccessory = (scanData.peripheral, advertisement)
            break
        }
        await timeoutTask.value
        guard let foundAccessory else {
            throw HughesAutoformersToolError.deviceNotInRange(device)
        }
        let peripheral = foundAccessory.peripheral
        // connect to device
        if await central.peripherals[peripheral] == false {
            print("[\(peripheral)]: Connecting...")
            // initiate connection
            try await central.connect(to: peripheral)
        }
        // cache MTU
        let maximumTransmissionUnit = try await central.maximumTransmissionUnit(for: peripheral)
        // get characteristics by UUID
        let servicesCache = try await central.cacheServices(for: peripheral)
        let connectionCache = GATTConnection(
            central: central,
            peripheral: peripheral,
            maximumTransmissionUnit: maximumTransmissionUnit,
            cache: servicesCache
        )
        // store connection cache
        return (connectionCache, foundAccessory.accessory)
    }
}
