//
//  VoltageView.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import SwiftUI
import Bluetooth
import GATT
import HughesAutoformers

struct VoltageView: View {
    
    let accessory: HughesAutoformersAccessory
    
    @EnvironmentObject
    private var store: AccessoryManager
    
    @State
    private var values = [(Date, PowerWatchdog.Status)]()
    
    var body: some View {
        VStack(alignment: .leading) {
            List {
                ForEach(values, id: \.0) { (date, status) in
                    HStack {
                        Text(date, style: .time)
                        VStack {
                            Text("Line \(status.line.rawValue)")
                            Text("\(status.voltage)V")
                            Text("\(status.amperage)A")
                            Text("\(status.watts)W")
                            Text("\(status.totalWatts)KWh")
                        }
                    }
                }
            }
        }
        .navigationTitle("Energy")
        .task {
            do {
                let stream = try await store.powerWatchdogStatus(for: accessory.id)
                Task {
                    do {
                        for try await value in stream {
                            values.append((Date(), value))
                        }
                    }
                    catch {
                        store.log("Unable to read voltage. \(error)")
                    }
                }
            }
            catch {
                store.log("Unable to read voltage. \(error)")
            }
        }
    }
}
