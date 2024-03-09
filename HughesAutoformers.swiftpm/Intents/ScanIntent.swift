//
//  ScanIntent.swift
//  
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import AppIntents
import SwiftUI
import Bluetooth
import GATT
import DarwinGATT
import HughesAutoformers

@available(iOS 16, *)
struct ScanIntent: AppIntent {
        
    static var title: LocalizedStringResource { "Scan for HughesAutoformers Bluetooth devices" }
    
    static var description: IntentDescription {
        IntentDescription(
            "Scan for nearby devices",
            categoryName: "Utility",
            searchKeywords: ["scan", "bluetooth", "HughesAutoformers", "battery", "BM20"]
        )
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Scan nearby devices for \(\.$duration) seconds")
    }
    
    @Parameter(
        title: "Duration",
        description: "Duration in seconds for scanning.",
        default: 1.5
    )
    var duration: TimeInterval
    
    @MainActor
    func perform() async throws -> some IntentResult {
        let store = AccessoryManager.shared
        try await store.central.wait(for: .poweredOn, warning: 2, timeout: 5)
        try await store.scan(duration: duration)
        let advertisements = store.peripherals.map { $0.value }
        return .result(
            value: advertisements.map { $0.id },
            view: view(for: advertisements)
        )
    }
}

@available(iOS 16, *)
@MainActor
private extension ScanIntent {
    
    func view(for results: [HughesAutoformersAccessory]) -> some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if results.isEmpty {
                    Text("No devices found.")
                        .padding(20)
                } else {
                    if results.count > 3 {
                        Text("Found \(results.count) devices.")
                            .padding(20)
                    } else {
                        ForEach(results) {
                            view(for: $0)
                                .padding(8)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
    
    func view(for accessory: HughesAutoformersAccessory) -> some View {
        HughesAutoformersAdvertisementRow(
            accessory: accessory
        )
    }
}
