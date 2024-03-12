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

internal extension HughesAutoformersAccessory {
    
    init?(scanData: ScanDataCache<NativeCentral.Peripheral, NativeCentral.Advertisement>) {
        if let powerWatchdog = PowerWatchdog(scanData: scanData) {
            self = .powerWatchdog(powerWatchdog)
        } else {
            return nil
        }
    }
}
