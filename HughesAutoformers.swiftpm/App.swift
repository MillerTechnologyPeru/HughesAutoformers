import Foundation
import SwiftUI
import CoreBluetooth
import Bluetooth
import GATT
import HughesAutoformers

@main
struct HughesAutoformersApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AccessoryManager.shared)
        }
    }
}
