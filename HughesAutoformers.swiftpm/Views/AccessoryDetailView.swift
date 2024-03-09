//
//  HughesAutoformersDetailView.swift
//  
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation
import SwiftUI
import Bluetooth
import GATT
import HughesAutoformers

struct HughesAutoformersAccessoryDetailView: View {
    
    let accessory: HughesAutoformersAccessory
    
    @EnvironmentObject
    private var store: AccessoryManager
    
    @State
    private var reloadTask: Task<Void, Never>?
    
    @State
    private var error: String?
    
    @State
    private var isReloading = false
    
    @State
    private var information: Result<HughesAutoformersAccessoryInfo, Error>?
    
    init(
        accessory: HughesAutoformersAccessory
    ) {
        self.accessory = accessory
    }
    
    var body: some View {
        VStack {
            StateView(
                accessory: accessory,
                information: information
            )
        }
        .refreshable {
            reload()
        }
        .onAppear {
            reload()
        }
        .onDisappear {
            reloadTask?.cancel()
        }
    }
}

extension HughesAutoformersAccessoryDetailView {
    
    func reload() {
        // accessory metadata
        if let accessoryInfo = store.accessoryInfo {
            self.information = accessoryInfo[accessory.type].flatMap { .success($0) }
        } else {
            // load accessory info
            fetchAccessoryInfo()
        }
    }
    
    func fetchAccessoryInfo() {
        // networking and Bluetooth
        let store = self.store
        isReloading = true
        reloadTask = Task(priority: .userInitiated) {
            defer { isReloading = false }
            do {
                let accessoryInfo = try await store.downloadAccessoryInfo()
                self.information = accessoryInfo[accessory.type]
                    .flatMap { .success($0) } ?? .failure(CocoaError(.coderValueNotFound))
            }
            catch {
                self.information = .failure(error)
            }
        }
    }
    
    func disconnect() {
        Task {
            await store.disconnect(accessory.id)
        }
    }
    
    var peripheral: NativePeripheral? {
        store[peripheral: accessory.id]
    }
    
    var isConnected: Bool {
        guard let peripheral else {
            return false
        }
        return store.connections.contains(peripheral)
    }
}

extension HughesAutoformersAccessoryDetailView {
    
    struct StateView: View {
        
        let accessory: HughesAutoformersAccessory
        
        let information: Result<HughesAutoformersAccessoryInfo, Error>?
        
        var body: some View {
            ScrollView {
                VStack(spacing: 16) {
                    // image view
                    VStack {
                        switch information {
                        case .success(let success):
                            CachedAsyncImage(
                                url: URL(string: success.image),
                                content: { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }, placeholder: {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                })
                        case .failure(let failure):
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(verbatim: failure.localizedDescription)
                        case nil:
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                    .frame(height: 250)
                    .padding()
                    
                    // Actions
                    switch accessory.type {
                    case .powerWatchdog:
                        NavigationLink(destination: {
                            VoltageView(accessory: accessory)
                        }, label: {
                            Text("Real-time Voltage")
                        })
                    }
                    
                    // Links
                    if let information = try? information?.get() {
                        if let manual = information.manual.flatMap({ URL(string: $0) }) {
                            Link("User Manual", destination: manual)
                        }
                        if let website = information.website.flatMap({ URL(string: $0) }) {
                            Link("Product Page", destination: website)
                        }
                    }
                }
            }
            .navigationTitle("\(accessory.id)")
        }
    }
}

/*
extension HughesAutoformersDetailView {
    
    func reload() {
        let oldTask = reloadTask
        reloadTask = Task {
            self.error = nil
            self.isReloading = true
            defer { self.isReloading = false }
            await oldTask?.value
            do {
                guard let beacons = store.peripherals[peripheral], beacons.isEmpty == false else {
                    throw CentralError.unknownPeripheral
                }
                self.address = beacons.compactMapValues { $0.address }.values.first
                self.capability = beacons.compactMap { $0.value.capability }.first ?? []
                self.ioCapability = beacons.compactMap { $0.value.ioCapability }.first ?? []
                // read characteristics
                try await store.central.connection(for: peripheral) { connection in
                    try await readCharacteristics(connection: connection)
                }
            }
            catch {
                self.error = error.localizedDescription
            }
        }
    }
    
    func readCharacteristics(connection: GATTConnection<NativeCentral>) async throws {
        var batteryService = ServiceSection(
            id: .batteryService,
            name: "Battery Service",
            characteristics: []
        )
        
        // read battery level
        if let characteristic = connection.cache.characteristic(.batteryLevel, service: .batteryService) {
            let data = try await connection.central.readValue(for: characteristic)
            guard data.count == 1 else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(.batteryLevel)
            }
            let value = data[0]
            batteryService.characteristics.append(
                CharacteristicItem(
                    id: characteristic.uuid.rawValue,
                    name: "Battery Level",
                    value: "\(value)%"
                )
            )
        }
        
        // read temperature and humidity
        var thermometerService = ServiceSection(
            id: TemperatureHumidityCharacteristic.service,
            name: "Mi Thermometer Service",
            characteristics: []
        )
        if let characteristic = connection.cache.characteristic(TemperatureHumidityCharacteristic.uuid, service: TemperatureHumidityCharacteristic.service) {
            let data = try await connection.central.readValue(for: characteristic)
            guard let value = TemperatureHumidityCharacteristic(data: data) else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(TemperatureHumidityCharacteristic.uuid)
            }
            thermometerService.characteristics += [
                CharacteristicItem(
                    id: characteristic.uuid.rawValue + "-" + "Temperature",
                    name: "Temperature",
                    value: value.temperature.description
                ),
                CharacteristicItem(
                    id: characteristic.uuid.rawValue + "-" + "Humidity",
                    name: "Humidity",
                    value: value.humidity.description
                ),
                CharacteristicItem(
                    id: characteristic.uuid.rawValue + "-" + "BatteryVoltage",
                    name: "Battery Voltage",
                    value: value.batteryVoltage.description
                )
            ]
        }
        
        // read device information
        var deviceInformationService = ServiceSection(
            id: .deviceInformation,
            name: "Device Information",
            characteristics: []
        )
        if let characteristic = connection.cache.characteristic(.manufacturerNameString, service: .deviceInformation) {
            let data = try await connection.central.readValue(for: characteristic)
            guard let value = String(data: data, encoding: .utf8) else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(.manufacturerNameString)
            }
            deviceInformationService.characteristics.append(
                CharacteristicItem(
                    id: BluetoothUUID.manufacturerNameString.rawValue,
                    name: "Manufacturer Name",
                    value: value
                )
            )
        }
        if let characteristic = connection.cache.characteristic(.modelNumberString, service: .deviceInformation) {
            let data = try await connection.central.readValue(for: characteristic)
            guard let value = String(data: data, encoding: .utf8) else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(.modelNumberString)
            }
            deviceInformationService.characteristics.append(
                CharacteristicItem(
                    id: BluetoothUUID.modelNumberString.rawValue,
                    name: "Model",
                    value: value
                )
            )
        }
        if let characteristic = connection.cache.characteristic(.serialNumberString, service: .deviceInformation) {
            let data = try await connection.central.readValue(for: characteristic)
            guard let value = String(data: data, encoding: .utf8) else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(.serialNumberString)
            }
            deviceInformationService.characteristics.append(
                CharacteristicItem(
                    id: BluetoothUUID.serialNumberString.rawValue,
                    name: "Serial Number",
                    value: value
                )
            )
        }
        if let characteristic = connection.cache.characteristic(.firmwareRevisionString, service: .deviceInformation) {
            let data = try await connection.central.readValue(for: characteristic)
            guard let value = String(data: data, encoding: .utf8) else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(.firmwareRevisionString)
            }
            deviceInformationService.characteristics.append(
                CharacteristicItem(
                    id: BluetoothUUID.firmwareRevisionString.rawValue,
                    name: "Firmware Revision",
                    value: value
                )
            )
        }
        if let characteristic = connection.cache.characteristic(.hardwareRevisionString, service: .deviceInformation) {
            let data = try await connection.central.readValue(for: characteristic)
            guard let value = String(data: data, encoding: .utf8) else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(.hardwareRevisionString)
            }
            deviceInformationService.characteristics.append(
                CharacteristicItem(
                    id: BluetoothUUID.hardwareRevisionString.rawValue,
                    name: "Hardware Revision",
                    value: value
                )
            )
        }
        if let characteristic = connection.cache.characteristic(.softwareRevisionString, service: .deviceInformation) {
            let data = try await connection.central.readValue(for: characteristic)
            guard let value = String(data: data, encoding: .utf8) else {
                throw HughesAutoformersAppError.invalidCharacteristicValue(.softwareRevisionString)
            }
            deviceInformationService.characteristics.append(
                CharacteristicItem(
                    id: BluetoothUUID.softwareRevisionString.rawValue,
                    name: "Software Revision",
                    value: value
                )
            )
        }
        
        // set services
        self.services = [
            thermometerService,
            batteryService,
            deviceInformationService
        ]
        .filter { $0.characteristics.isEmpty == false }
    }
}

extension HughesAutoformersDetailView {
    
    struct StateView: View {
        
        let product: ProductID
        
        let address: BluetoothAddress?
        
        let version: UInt8
        
        let capability: HughesAutoformers.Capability
        
        let ioCapability: HughesAutoformers.Capability.IO
        
        let services: [ServiceSection]
        
        var body: some View {
            List {
                Section("Advertisement") {
                    if let address = self.address {
                        SubtitleRow(
                            title: Text("Address"),
                            subtitle: Text(verbatim: address.rawValue)
                        )
                    }
                    SubtitleRow(
                        title: Text("Version"),
                        subtitle: Text(verbatim: version.description)
                    )
                    #if DEBUG
                    if capability.isEmpty == false {
                        SubtitleRow(
                            title: Text("Capability"),
                            subtitle: Text(verbatim: capability.description)
                        )
                    }
                    if ioCapability.isEmpty == false {
                        SubtitleRow(
                            title: Text("IO Capability"),
                            subtitle: Text(verbatim: ioCapability.description)
                        )
                    }
                    #endif
                }
                ForEach(services) { service in
                    Section(service.name) {
                        ForEach(service.characteristics) { characteristic in
                            SubtitleRow(
                                title: Text(characteristic.name),
                                subtitle: Text(verbatim: characteristic.value)
                            )
                        }
                    }
                }
            }
            .navigationTitle("\(product.description)")
        }
    }
}

extension HughesAutoformersDetailView {
    
    struct ServiceSection: Equatable, Identifiable {
        
        let id: BluetoothUUID
        
        let name: LocalizedStringKey
        
        var characteristics: [CharacteristicItem]
    }
    
    struct CharacteristicItem: Equatable, Identifiable {
        
        let id: String
        
        let name: LocalizedStringKey
        
        let value: String
    }
}
*/
