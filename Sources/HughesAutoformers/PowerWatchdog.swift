//
//  PowerWatchdog.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import Bluetooth
import GATT

/// Hughes Autoformers Power Watchdog
public struct PowerWatchdog: Equatable, Hashable, Codable, Identifiable, Sendable {
    
    internal static var namePrefixes: Set<String> {
        [
            "PMS",
            "APMS"
        ]
    }
    
    public static var service: BluetoothUUID {
        .powerWatchdogService
    }
    
    public static var type: HughesAutoformersAccessoryType { .powerWatchdog }
    
    public let id: ID
    
    public let hardwareRevision: HardwareRevision
}

public extension PowerWatchdog {
    
    init?(
        name: String,
        serviceUUIDs: [BluetoothUUID],
        manufacturerData: GATT.ManufacturerSpecificData
    ) {
        guard serviceUUIDs == [.powerWatchdogService],
              let prefix = Self.namePrefixes.first(where: { name.hasPrefix($0) }),
              manufacturerData.additionalData.count >= 6 else {
            return nil
        }
        let idString = name
            .replacingOccurrences(of: prefix, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let id = UInt64(idString, radix: 16) else {
            return nil
        }
        var hardwareRevisionString = UInt64(
            littleEndian:
                UInt64(
                    bytes: (
                        manufacturerData.additionalData[5],
                        manufacturerData.additionalData[4],
                        manufacturerData.additionalData[3],
                        manufacturerData.additionalData[2],
                        manufacturerData.additionalData[1],
                        manufacturerData.additionalData[0],
                        manufacturerData.companyIdentifier.rawValue.bigEndian.bytes.0,
                        manufacturerData.companyIdentifier.rawValue.bigEndian.bytes.1
                    )
                )
        ).toHexadecimal()
        while hardwareRevisionString.last == "0" {
            hardwareRevisionString.removeLast()
        }
        guard let hardwareRevision = UInt64(hardwareRevisionString, radix: 16) else {
            return nil
        }
        self.id = ID(rawValue: id)
        self.hardwareRevision = HardwareRevision(rawValue: hardwareRevision)
    }
}

// MARK: - Supporting Types

public extension PowerWatchdog {
    
    /// Hughes Autoformers Power Watchdog Identifier
    struct ID: RawRepresentable, Equatable, Hashable, Codable, Sendable {
        
        public let rawValue: UInt64
        
        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
    }
}

extension PowerWatchdog.ID: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt64) {
        self.init(rawValue: value)
    }
}

extension PowerWatchdog.ID: CustomStringConvertible {
    
    public var description: String {
        String(rawValue, radix: 16).uppercased()
    }
}

public extension PowerWatchdog {
    
    /// Hughes Autoformers Power Watchdog Hardware Revision
    struct HardwareRevision: RawRepresentable, Equatable, Hashable, Codable, Sendable {
        
        public let rawValue: UInt64
        
        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
    }
}

extension PowerWatchdog.HardwareRevision: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt64) {
        self.init(rawValue: value)
    }
}

extension PowerWatchdog.HardwareRevision: CustomStringConvertible {
    
    public var description: String {
        String(rawValue, radix: 16).uppercased()
    }
}
