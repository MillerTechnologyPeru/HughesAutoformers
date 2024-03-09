//
//  PowerWatchdogNotificationCharacteristic.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import Bluetooth
import GATT

public enum PowerWatchdogNotificationCharacteristic: Equatable, Hashable, Sendable {
    
    case line(Line)
    case energy(Energy)
}

public extension PowerWatchdogNotificationCharacteristic {
    
    var uuid: BluetoothUUID { .powerWatchdogRXCharacteristic }
    
    init?(data: Data) {
        guard data.count == 20 else {
            return nil
        }
        switch data[0] {
        case Line.opcode:
            guard let value = Line(data: data) else {
                return nil
            }
            self = .line(value)
        case Energy.opcode:
            guard let value = Energy(data: data) else {
                return nil
            }
            self = .energy(value)
        default:
            return nil
        }
    }
}

public extension PowerWatchdogNotificationCharacteristic {
    
    struct Line: Equatable, Hashable, Sendable {
        
        static var opcode: UInt8 { 0x00 }
        
        public init?(data: Data) {
            guard data.first == Self.opcode,
                  data.count == 20 else {
                return nil
            }
        }
    }
}

public extension PowerWatchdogNotificationCharacteristic {
    
    struct Energy: Equatable, Hashable, Sendable {
        
        static var opcode: UInt8 { 0x01 }
        
        internal let rawVoltage: Int32
        
        public var voltage: Float {
            Float(rawVoltage) / 10_000
        }
        
        public init?(data: Data) {
            guard data.first == Self.opcode,
                  data.count == 20 else {
                return nil
            }
            self.rawVoltage = Int32(bigEndian: Int32(bytes: (data[3], data[4], data[5], data[6])))
        }
    }
}
