//
//  PowerWatchdog.swift
//
//
//  Created by Alsey Coleman Miller on 3/12/24.
//

import Foundation
import Bluetooth
import GATT
import HughesAutoformers

internal extension PowerWatchdog {
    
    init?(scanData: ScanDataCache<NativeCentral.Peripheral, NativeCentral.Advertisement>) {
        guard let name = scanData.localName,
              let serviceUUIDs = scanData.serviceUUIDs,
              let manufacturerData = scanData.manufacturerData else {
            return nil
        }
        self.init(
            name: name,
            serviceUUIDs: serviceUUIDs,
            manufacturerData: manufacturerData
        )
    }
}

internal extension GATTConnection {
    
    func powerWatchdogStatus() async throws -> AsyncIndefiniteStream<PowerWatchdog.Status> {
        guard let characteristic = cache.characteristic(.powerWatchdogTXCharacteristic, service: .powerWatchdogService) else {
            throw HughesAutoformersToolError.characteristicNotFound(.powerWatchdogTXCharacteristic)
        }
        return try await central.powerWatchdogStatus(characteristic: characteristic)
    }
}
