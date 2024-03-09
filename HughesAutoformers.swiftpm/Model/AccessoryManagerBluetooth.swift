//
//  AccessoryManagerBluetooth.swift
//  
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import Bluetooth
import GATT
import DarwinGATT
import HughesAutoformers

public extension AccessoryManager {
    
    /// The Bluetooth LE peripheral for the speciifed device identifier..
    subscript (peripheral id: HughesAutoformersAccessory.ID) -> NativeCentral.Peripheral? {
        return peripherals.first(where: { $0.value.id == id })?.key
    }
    
    func scan(duration: TimeInterval? = nil) async throws {
        let bluetoothState = await central.state
        guard bluetoothState == .poweredOn else {
            throw HughesAutoformersAppError.bluetoothUnavailable
        }
        let filterDuplicates = true //preferences.filterDuplicates
        self.peripherals.removeAll(keepingCapacity: true)
        stopScanning()
        let services = Set([
            PowerWatchdog.service
        ])
        let scanStream = central.scan(
            with: services,
            filterDuplicates: filterDuplicates
        )
        self.scanStream = scanStream
        let task = Task { [unowned self] in
            for try await scanData in scanStream {
                guard await found(scanData) else { continue }
            }
        }
        if let duration = duration {
            precondition(duration > 0.001)
            try await Task.sleep(timeInterval: duration)
            scanStream.stop()
            try await task.value // throw errors
        } else {
            // error not thrown
            Task { [unowned self] in
                do { try await task.value }
                catch is CancellationError { }
                catch {
                    self.log("Error scanning: \(error)")
                }
            }
        }
    }
    
    func stopScanning() {
        scanStream?.stop()
        scanStream = nil
    }
    
    @discardableResult
    func connect(to accessory: HughesAutoformersAccessory.ID) async throws -> GATTConnection<NativeCentral> {
        let central = self.central
        guard let peripheral = self[peripheral: accessory] else {
            throw CentralError.unknownPeripheral
        }
        if let connection = self.connectionsByPeripherals[peripheral] {
            return connection
        }
        // connect
        if await loadConnections.contains(peripheral) == false {
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
        self.connectionsByPeripherals[peripheral] = connectionCache
        return connectionCache
    }
    
    func disconnect(_ accessory: HughesAutoformersAccessory.ID) async {
        guard let peripheral = self[peripheral: accessory] else {
            assertionFailure()
            return
        }
        // stop notifications
        await central.disconnect(peripheral)
    }
    
    /// Recieve Power Watchdog values.
    func powerWatchdogStatus(
        for accessory: HughesAutoformersAccessory.ID
    ) async throws -> AsyncIndefiniteStream<PowerWatchdog.Status> {
        let connection = try await connect(to: accessory)
        return try await connection.powerWatchdogStatus()
    }
}

internal extension GATTConnection {
    
    func powerWatchdogStatus() async throws -> AsyncIndefiniteStream<PowerWatchdog.Status> {
        guard let characteristic = cache.characteristic(.powerWatchdogTXCharacteristic, service: .powerWatchdogService) else {
            throw HughesAutoformersAppError.characteristicNotFound(.powerWatchdogRXCharacteristic)
        }
        return try await central.powerWatchdogStatus(characteristic: characteristic)
    }
}

internal extension AccessoryManager {
    
    func observeBluetoothState() {
        // observe state
        Task { [weak self] in
            while let self = self {
                let newState = await self.central.state
                let oldValue = self.state
                if newState != oldValue {
                    self.state = newState
                }
                try await Task.sleep(timeInterval: 0.5)
            }
        }
        // observe connections
        Task { [weak self] in
            while let self = self {
                let newState = await self.loadConnections
                let oldValue = self.connections
                let disconnected = self.connectionsByPeripherals
                    .filter { newState.contains($0.value.peripheral) }
                    .keys
                if newState != oldValue, disconnected.isEmpty == false {
                    for peripheral in disconnected {
                        self.connectionsByPeripherals[peripheral] = nil
                    }
                }
                try await Task.sleep(timeInterval: 0.2)
            }
        }
    }
    
    var loadConnections: Set<NativePeripheral> {
        get async {
            let peripherals = await self.central
                .peripherals
                .filter { $0.value }
                .map { $0.key }
            return Set(peripherals)
        }
    }
    
    func found(_ scanData: ScanData<NativeCentral.Peripheral, NativeCentral.Advertisement>) async -> Bool {
        
        // aggregate scan data
        assert(Thread.isMainThread)
        let oldCacheValue = scanResults[scanData.peripheral]
        // cache discovered peripheral in background
        let cache = await Task.detached { [weak central] in
            assert(Thread.isMainThread == false)
            var cache = oldCacheValue ?? ScanDataCache(scanData: scanData)
            cache += scanData
            #if canImport(CoreBluetooth)
            cache.name = try? await central?.name(for: scanData.peripheral)
            for serviceUUID in scanData.advertisementData.overflowServiceUUIDs ?? [] {
                cache.overflowServiceUUIDs.insert(serviceUUID)
            }
            #endif
            return cache
        }.value
        scanResults[scanData.peripheral] = cache
        assert(Thread.isMainThread)
        
        // cache identified accessory
        let serviceUUIDs = Array(cache.serviceUUIDs)
        if let name = cache.name,
              serviceUUIDs.isEmpty == false,
              let manufacturerData = cache.manufacturerData,
              let powerWatchdog = PowerWatchdog(name: name, serviceUUIDs: serviceUUIDs, manufacturerData: manufacturerData) {
            self.peripherals[scanData.peripheral] = .powerWatchdog(powerWatchdog)
            return true
        } else {
            return false
        }
    }
}
