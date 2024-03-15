//
//  PowerWatchdogNotificationCharacteristic.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import Bluetooth
import GATT

public extension PowerWatchdog {
    
    enum NotificationCharacteristic: Equatable, Hashable, Sendable {
        
        case energy(Energy)
        case line(LineValues)
    }
}

public extension PowerWatchdog.NotificationCharacteristic {
    
    static var uuid: BluetoothUUID { .powerWatchdogRXCharacteristic }
    
    internal static var length: Int { 20 }
    
    init?(data: Data) {
        guard data.count == Self.length else {
            return nil
        }
        switch data[0] {
        case LineValues.opcode:
            guard let value = LineValues(data: data) else {
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

public extension PowerWatchdog.NotificationCharacteristic {
    
    struct Energy: Equatable, Hashable, Sendable {
        
        public static var opcode: UInt8 { 0x01 }
        
        internal let reservedValue0: Int16
        
        public let voltage: Int32
        
        public let amperage: Int32
        
        public let watts: Int32
        
        public let totalWatts: Int32
        
        internal let reservedValue1: UInt8
        
        public init?(data: Data) {
            guard data.first == Self.opcode,
                  data.count == PowerWatchdog.NotificationCharacteristic.length else {
                return nil
            }
            self.reservedValue0 = Int16(bigEndian: Int16(bytes: (data[1], data[2])))
            self.voltage = Int32(bigEndian: Int32(bytes: (data[3], data[4], data[5], data[6])))
            self.amperage = Int32(bigEndian: Int32(bytes: (data[7], data[8], data[9], data[10])))
            self.watts = Int32(bigEndian: Int32(bytes: (data[11], data[12], data[13], data[14])))
            self.totalWatts = Int32(bigEndian: Int32(bytes: (data[15], data[16], data[17], data[18])))
            self.reservedValue1 = data[19]
        }
    }
}

public extension PowerWatchdog.NotificationCharacteristic {
    
    struct LineValues: Equatable, Hashable, Sendable {
        
        public static var opcode: UInt8 { 0x00 }
        
        public let line: PowerWatchdog.Line
        
        public let frequency: Int32
        
        public init?(data: Data) {
            guard data.first == Self.opcode,
                  data.count == PowerWatchdog.NotificationCharacteristic.length else {
                return nil
            }
            let lineBytes = (data[17], data[18], data[19])
            switch lineBytes {
                case (0, 0, 0):
                    self.line = 0
                case (1, 1, 1):
                    self.line = 1
                default:
                    return nil
            }
            self.frequency = Int32(bigEndian: Int32(bytes: (data[11], data[12], data[13], data[14])))
        }
    }
}

public extension PowerWatchdog {
    
    struct Status: Equatable, Hashable, Codable, Sendable {
        
        public let line: Line
        
        public let frequency: Float
        
        public let voltage: Float
        
        public let amperage: Float
        
        public let watts: Float
        
        public let totalWatts: Float
        
        public init(
            energy: PowerWatchdog.NotificationCharacteristic.Energy,
            line lineValues: PowerWatchdog.NotificationCharacteristic.LineValues
        ) {
            self.line = lineValues.line
            self.voltage = Float(energy.voltage) / 10_000
            self.amperage = Float(energy.amperage) / 10_000
            self.watts = Float(energy.watts) / 10_000
            self.totalWatts = Float(energy.totalWatts) / 10_000
            self.frequency = Float(lineValues.frequency) / 100
        }
    }
}

// MARK: - Central

public extension CentralManager {
    
    /// Recieve stream of power measurements.
    func powerWatchdogStatus(
        characteristic: Characteristic<Peripheral, AttributeID>
    ) async throws -> AsyncIndefiniteStream<PowerWatchdog.Status> {
        typealias Notification = PowerWatchdog.NotificationCharacteristic
        assert(characteristic.uuid == .powerWatchdogTXCharacteristic)
        let notifications = try await self.notify(for: characteristic)
        return AsyncIndefiniteStream<PowerWatchdog.Status> { build in
            var lastPacket: PowerWatchdog.NotificationCharacteristic?
            for try await data in notifications {
                guard let notification = Notification(data: data) else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid data."))
                }
                switch (lastPacket, notification) {
                case let (nil, .energy(energy)):
                    lastPacket = .energy(energy)
                case let (.energy(energy), .line(line)):
                    let status = PowerWatchdog.Status(
                        energy: energy,
                        line: line
                    )
                    lastPacket = nil
                    build(status)
                default:
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Inexpected value \(notification)"))
                }
            }
        }
    }
}
