//
//  ScanDataCache.swift
//  
//
//  Created by Alsey Coleman Miller on 3/12/24.
//

import Foundation
import Bluetooth
import GATT

public struct ScanDataCache <Peripheral: Peer, Advertisement: AdvertisementData>: Equatable, Hashable {
    
    /// Last scan result.
    public internal(set) var scanData: GATT.ScanData<Peripheral, Advertisement>
    
    public internal(set) var localName: String?
    
    public internal(set) var manufacturerData: GATT.ManufacturerSpecificData?
    
    /// This value is available if the broadcaster (peripheral) provides its Tx power level in its advertising packet.
    /// Using the RSSI value and the Tx power level, it is possible to calculate path loss.
    public internal(set) var txPowerLevel: Double?
    
    /// Service-specific advertisement data.
    public var serviceData: [BluetoothUUID: Data]? {
        _serviceData
    }
    
    private var _serviceData = [BluetoothUUID: Data]()
    
    /// An array of service UUIDs
    public var serviceUUIDs: [BluetoothUUID]? {
        Array(_serviceUUIDs)
    }
    
    private var _serviceUUIDs = Set<BluetoothUUID>()
    
    /// An array of one or more ``BluetoothUUID``, representing Service UUIDs.
    private var _solicitedServiceUUIDs = Set<BluetoothUUID>()
    
    /// An array of one or more `BluetoothUUID`, representing Service UUIDs.
    public var solicitedServiceUUIDs: [BluetoothUUID]? {
        Array(_solicitedServiceUUIDs)
    }
    
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
        cache.localName = scanData.advertisementData.localName ?? cache.localName
        cache.txPowerLevel = scanData.advertisementData.txPowerLevel
        cache.manufacturerData = scanData.advertisementData.manufacturerData ?? cache.manufacturerData
        for serviceUUID in scanData.advertisementData.serviceUUIDs ?? [] {
            cache._serviceUUIDs.insert(serviceUUID)
        }
        for (serviceUUID, serviceData) in scanData.advertisementData.serviceData ?? [:] {
            cache._serviceData[serviceUUID] = serviceData
        }
    }
}

extension ScanDataCache: Identifiable {
    
    public var id: Peripheral.ID {
        scanData.id
    }
}

extension ScanDataCache: GATT.AdvertisementData { }
