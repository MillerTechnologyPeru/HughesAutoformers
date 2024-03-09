//
//  AccessoryInfo.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import HughesAutoformers

/// HughesAutoformers Accessory Info
public struct HughesAutoformersAccessoryInfo: Equatable, Hashable, Codable, Sendable {
        
    public let symbol: String
    
    public let image: String
        
    public let manual: String?
        
    public let website: String?
}

public extension HughesAutoformersAccessoryInfo {
    
    struct Database: Equatable, Hashable, Sendable {
        
        public let accessories: [HughesAutoformersAccessoryType: HughesAutoformersAccessoryInfo]
    }
}

public extension HughesAutoformersAccessoryInfo.Database {
    
    subscript(type: HughesAutoformersAccessoryType) -> HughesAutoformersAccessoryInfo? {
        accessories[type]
    }
}

public extension HughesAutoformersAccessoryInfo.Database {
    
    internal static let encoder: PropertyListEncoder = {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        return encoder
    }()
    
    internal static let decoder: PropertyListDecoder = {
        let decoder = PropertyListDecoder()
        return decoder
    }()
    
    init(propertyList data: Data) throws {
        self = try Self.decoder.decode(HughesAutoformersAccessoryInfo.Database.self, from: data)
    }
    
    func encodePropertyList() throws -> Data {
        try Self.encoder.encode(self)
    }
}

extension HughesAutoformersAccessoryInfo.Database: Codable {
    
    public init(from decoder: Decoder) throws {
        let accessories = try [String: HughesAutoformersAccessoryInfo].init(from: decoder)
        self.accessories = try accessories.mapKeys {
            guard let key = HughesAutoformersAccessoryType(rawValue: $0) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Invalid key \($0)"))
            }
            return key
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        try accessories
            .mapKeys { $0.rawValue }
            .encode(to: encoder)
    }
}
