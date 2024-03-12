//
//  Bluetooth.swift
//
//
//  Created by Alsey Coleman Miller on 3/12/24.
//

#if os(Linux)
import Glibc
import BluetoothLinux
#elseif os(macOS)
import Darwin
import DarwinGATT
#endif

import Foundation
import Bluetooth
import GATT
import ArgumentParser

#if os(Linux)
typealias LinuxCentral = GATTCentral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias LinuxPeripheral = GATTPeripheral<BluetoothLinux.HostController, BluetoothLinux.L2CAPSocket>
typealias NativeCentral = LinuxCentral
typealias NativePeripheral = LinuxPeripheral
#elseif os(macOS)
typealias NativeCentral = DarwinCentral
typealias NativePeripheral = DarwinPeripheral
#else
#error("Unsupported platform")
#endif

extension AsyncParsableCommand {
    
    func loadBluetooth(_ index: UInt = 0) async throws -> NativeCentral {
        
        #if os(Linux)
        var controllers = await HostController.controllers
        // keep trying to load Bluetooth device
        if controllers.isEmpty || controllers.count < index {
            log?("No Bluetooth adapters found")
            throw HughesAutoformersToolError.bluetoothUnavailable
        }
        var hostController: HostController = controllers[Int(index)]
        let address = try await hostController.readDeviceAddress()
        log?("Bluetooth Address: \(address)")
        let clientOptions = GATTCentralOptions(
            maximumTransmissionUnit: .max
        )
        let central = LinuxCentral(
            hostController: hostController,
            options: clientOptions,
            socket: BluetoothLinux.L2CAPSocket.self
        )
        #elseif os(macOS)
        let central = DarwinCentral()
        #else
        #error("Invalid platform")
        #endif
        
        #if DEBUG
        central.log = { print("Central: \($0)") }
        #endif
        
        #if os(macOS)
        // wait until XPC connection to blued is established and hardware is on
        try await central.waitPowerOn()
        #endif
        
        return central
    }
}
