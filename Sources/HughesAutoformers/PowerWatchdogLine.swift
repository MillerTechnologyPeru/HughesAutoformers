//
//  PowerWatchdogLine.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

public extension PowerWatchdog {
    
    /// Hughes Autoformers Power Watchdog Line
    struct Line: RawRepresentable, Equatable, Hashable, Codable, Sendable {
        
        public let rawValue: UInt8
        
        public init(rawValue: UInt8) {
            self.rawValue = rawValue
        }
    }
}

extension PowerWatchdog.Line: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: UInt8) {
        self.init(rawValue: value)
    }
}

extension PowerWatchdog.Line: CustomStringConvertible {
    
    public var description: String {
        rawValue.description
    }
}

internal extension PowerWatchdog.Line {
    
    var bytes: (UInt8, UInt8, UInt8) {
        return (rawValue, rawValue, rawValue)
    }
}
