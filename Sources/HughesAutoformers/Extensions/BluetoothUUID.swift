//
//  BluetoothUUID.swift
//  
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import Bluetooth

public extension BluetoothUUID {
    
    static var powerWatchdogService: BluetoothUUID {
        .bit16(0xFFE0)
    }
    
    static var powerWatchdogRXCharacteristic: BluetoothUUID {
        .bit16(0xFFF5)
    }
    
    static var powerWatchdogTXCharacteristic: BluetoothUUID {
        .bit16(0xFFE2)
    }
    
    static var powerWatchdogRegWriteCharacteristic: BluetoothUUID {
        .bit16(0x1003)
    }
    
    static var powerWatchdogRegReadCharacteristic: BluetoothUUID {
        .bit16(0x1004)
    }
    
    static var powerWatchdogRegCharacteristic: BluetoothUUID {
        .bit16(0x1005)
    }
    
    static var powerWatchdogResetService: BluetoothUUID {
        BluetoothUUID(rawValue: "F000FFDO-0451-4000-B000-000000000000")!
    }
}
