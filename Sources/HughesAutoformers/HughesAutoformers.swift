import Foundation
import Bluetooth
import GATT

public enum HughesAutoformersAccessory: Equatable, Hashable, Codable, Sendable {
    
    case powerWatchdog(PowerWatchdog)
}

public enum HughesAutoformersAccessoryType: String, Codable, CaseIterable {
    
    case powerWatchdog = "PowerWatchdog"
}

public extension HughesAutoformersAccessory {
    
    var type: HughesAutoformersAccessoryType {
        switch self {
        case .powerWatchdog:
            return .powerWatchdog
        }
    }
}

extension HughesAutoformersAccessory: Identifiable {
    
    public var id: String {
        switch self {
        case .powerWatchdog(let powerWatchdog):
            return powerWatchdog.id.description
        }
    }
}
