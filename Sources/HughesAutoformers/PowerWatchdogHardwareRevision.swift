//
//  PowerWatchdogHardwareRevision.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

public extension PowerWatchdog {
    
    /// Hughes Autoformers Power Watchdog Hardware Revision
    struct HardwareRevision: RawRepresentable, Equatable, Hashable, Codable, Sendable {
        
        public let rawValue: UInt64
        
        public init(rawValue: UInt64) {
            self.rawValue = rawValue
        }
    }
}

// MARK: - ExpressibleByIntegerLiteral

extension PowerWatchdog.HardwareRevision: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt64) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension PowerWatchdog.HardwareRevision: CustomStringConvertible {
    
    public var description: String {
        String(rawValue, radix: 16).uppercased()
    }
}
