//
//  ScanDataCache.swift
//  BluetoothAccessoryKit
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import Bluetooth
import GATT

public struct ScanDataCache <Peripheral: Peer, Advertisement: AdvertisementData>: Equatable, Hashable {
    
    public internal(set) var scanData: GATT.ScanData<Peripheral, Advertisement>
    
    /// GAP or advertised name
    public internal(set) var name: String?
    
    /// Advertised name
    public internal(set) var advertisedName: String?
    
    public internal(set) var manufacturerData: GATT.ManufacturerSpecificData?
    
    /// This value is available if the broadcaster (peripheral) provides its Tx power level in its advertising packet.
    /// Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    public internal(set) var txPowerLevel: Double?
    
    /// Service-specific advertisement data.
    public internal(set) var serviceData = [BluetoothUUID: Data]()
    
    /// An array of service UUIDs
    public internal(set) var serviceUUIDs = Set<BluetoothUUID>()
    
    /// An array of one or more ``BluetoothUUID``, representing Service UUIDs.
    public internal(set) var solicitedServiceUUIDs = Set<BluetoothUUID>()
    
    /// An array of one or more ``BluetoothUUID``, representing Service UUIDs that were found in the “overflow” area of the advertisement data.
    public internal(set) var overflowServiceUUIDs = Set<BluetoothUUID>()
    
    /// Advertised iBeacon
    public internal(set) var beacon: AppleBeacon?
    
    internal init(scanData: GATT.ScanData<Peripheral, Advertisement>) {
        self.scanData = scanData
        self += scanData
    }
    
    internal static func += (cache: inout ScanDataCache, scanData: GATT.ScanData<Peripheral, Advertisement>) {
        cache.scanData = scanData
        cache.advertisedName = scanData.advertisementData.localName
        if cache.name == nil {
            cache.name = scanData.advertisementData.localName
        }
        cache.txPowerLevel = scanData.advertisementData.txPowerLevel
        cache.manufacturerData = scanData.advertisementData.manufacturerData
        for serviceUUID in scanData.advertisementData.serviceUUIDs ?? [] {
            cache.serviceUUIDs.insert(serviceUUID)
        }
        for (serviceUUID, serviceData) in scanData.advertisementData.serviceData ?? [:] {
            cache.serviceData[serviceUUID] = serviceData
        }
    }
}

extension ScanDataCache: Identifiable {
    
    public var id: Peripheral.ID {
        scanData.id
    }
}
