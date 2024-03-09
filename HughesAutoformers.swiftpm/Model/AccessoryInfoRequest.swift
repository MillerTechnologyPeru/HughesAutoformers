//
//  AccessoryInfoRequest.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation

public extension URLClient {
    
    func downloadHughesAutoformersAccessoryInfo() async throws -> HughesAutoformersAccessoryInfo.Database {
        let url = URL(string: "https://raw.githubusercontent.com/MillerTechnologyPeru/HughesAutoformers/master/HughesAutoformers.swiftpm/HughesAutoformers.plist")!
        let (data, urlResponse) = try await self.data(for: URLRequest(url: url))
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw URLError(.unknown)
        }
        guard httpResponse.statusCode == 200 else {
            throw URLError(.resourceUnavailable)
        }
        let decoder = PropertyListDecoder()
        return try decoder.decode(HughesAutoformersAccessoryInfo.Database.self, from: data)
    }
}
