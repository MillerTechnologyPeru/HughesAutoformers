//
//  Store.swift
//
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import SwiftUI
import CoreBluetooth
import Bluetooth
import GATT
import DarwinGATT
import HughesAutoformers

@MainActor
public final class AccessoryManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published
    public internal(set) var state: DarwinBluetoothState = .unknown
    
    public var isScanning: Bool {
        scanStream != nil
    }
    
    @Published
    public internal(set) var peripherals = [NativeCentral.Peripheral: HughesAutoformersAccessory]()
    
    /// All discovered devices.
    @Published
    public internal(set) var scanResults = [NativeCentral.Peripheral: ScanDataCache<NativeCentral.Peripheral, NativeCentral.Advertisement>]()
    
    public var connections: Set<NativeCentral.Peripheral> {
        Set(connectionsByPeripherals.keys)
    }
    
    @Published
    internal var connectionsByPeripherals = [NativeCentral.Peripheral: GATTConnection<NativeCentral>]()
    
    internal lazy var central = NativeCentral()
    
    @Published
    internal var scanStream: AsyncCentralScan<NativeCentral>?
    
    internal lazy var urlSession = loadURLSession()
    
    internal lazy var fileManager = FileManager()
    
    internal lazy var documentDirectory = loadDocumentDirectory()
    
    internal lazy var cachesDirectory = loadCachesDirectory()
    
    @Published
    internal var fileManagerCache = FileManagerCache()
    
    // MARK: - Initialization
    
    public static let shared = AccessoryManager()
    
    private init() {
        central.log = { [unowned self] in self.log("📲 Central: " + $0) }
        observeBluetoothState()
    }
}
