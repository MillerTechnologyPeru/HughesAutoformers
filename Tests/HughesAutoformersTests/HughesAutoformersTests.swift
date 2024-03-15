import Foundation
import Bluetooth
#if canImport(BluetoothGAP)
import BluetoothGAP
#endif
import XCTest
@testable import HughesAutoformers

final class HughesAutoformersTests: XCTestCase {
    
    #if canImport(BluetoothGAP)
    func testPowerWatchdogAdvertisement() throws {
        
        /*
         HCI Event 0x0000  60:98:66:F2:5E:62  LE - Ext ADV - 1 Report - Normal - Public - 60:98:66:F2:5E:62  -74 dBm - Manufacturer Specific Data - Channel 38
             Parameter Length: 57 (0x39)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:98:66:F2:5E:62
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -74 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 31
                 Flags: 0x6
                     LE Limited General Discoverable Mode
                     BR/EDR Not Supported
                 16 Bit UUIDs(Incomplete): 0XFFE0
                 Data: 02 01 06 03 02 E0 FF 17 FF 60 98 66 F2 5E 62 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
         HCI Event 0x0000                     00000000: 3E39 0D01 1326 0062 5EF2 6698 6081 00FF  >9...&.b^.f.`...
         HCI Event 0x0000  60:98:66:F2:5E:62  LE - Ext ADV - 1 Report - Normal - Public - 60:98:66:F2:5E:62  -74 dBm - PMS      025E62E208         - Channel 38
             Parameter Length: 55 (0x37)
             Num Reports: 0X01
             Report 0
                 Event Type: Connectable Advertising - Scannable Advertising - Scan Response - Legacy Advertising PDUs Used - Complete -
                 Address Type: Public
                 Peer Address: 60:98:66:F2:5E:62
                 Primary PHY: 1M
                 Secondary PHY: No Packets
                 Advertising SID: Unavailable
                 Tx Power: Unavailable
                 RSSI: -74 dBm
                 Periodic Advertising Interval: 0.000000ms (0x0)
                 Direct Address Type: Public
                 Direct Address: 00:00:00:00:00:00
                 Data Length: 29
                 Local Name: PMS      025E62E208
                 Data: 1C 09 50 4D 53 20 20 20 20 20 20 30 32 35 45 36 32 45 32 30 38 20 20 20 20 20 20 20 20
         */
        
        let advertismentData: LowEnergyAdvertisingData = [0x02, 0x01, 0x06, 0x03, 0x02, 0xE0, 0xFF, 0x17, 0xFF, 0x60, 0x98, 0x66, 0xF2, 0x5E, 0x62, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
        
        let scanResponse: LowEnergyAdvertisingData = [0x1C, 0x09, 0x50, 0x4D, 0x53, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x30, 0x32, 0x35, 0x45, 0x36, 0x32, 0x45, 0x32, 0x30, 0x38, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20]
        
        guard let serviceUUIDs = advertismentData.serviceUUIDs,
            let manufacturerData = advertismentData.manufacturerData,
            let name = scanResponse.localName else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(serviceUUIDs, [PowerWatchdog.service])
        XCTAssertEqual(name, "PMS      025E62E208        ")
        
        guard let accessory = PowerWatchdog(
            name: name,
            serviceUUIDs: serviceUUIDs,
            manufacturerData: manufacturerData
        ) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(accessory.id, 0x025E62E208)
        XCTAssertEqual(accessory.id.description, "APMS25E62E208")
        XCTAssertEqual(accessory.hardwareRevision, 0x609866F25E62)
    }
    #endif
    
    func testPowerWatchdogEnergyNotification() {
        
        do {
            let data = Data([0x01, 0x03, 0x20, 0x00, 0x12, 0x5b, 0xa4, 0x00, 0x01, 0x43, 0x07, 0x00, 0x93, 0xc8, 0x08, 0x00, 0x6a, 0xcd, 0x68, 0x00])
            
            guard let notification = PowerWatchdog.NotificationCharacteristic(data: data),
                  case let .energy(energy) = notification else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(energy.voltage, 0x00125ba4)
            XCTAssertEqual(energy.reservedValue0, 800)
            XCTAssertEqual(Float(energy.voltage) / 10_000, 120.3108)
            XCTAssertEqual(Float(energy.amperage) / 10_000, 8.2695)
            XCTAssertEqual(Float(energy.watts) / 10_000, 968.5)
            XCTAssertEqual(Float(energy.totalWatts) / 10_000, 699.94)
        }
        
        do {
            let data = Data([0x01, 0x03, 0x20, 0x00, 0x12, 0x94, 0xFB, 0x00, 0x01, 0x55, 0xD2, 0x00, 0x9E, 0x8A, 0x99, 0x00, 0x00, 0x24, 0xB8, 0x00])
            
            guard let notification = PowerWatchdog.NotificationCharacteristic(data: data),
                  case let .energy(energy) = notification else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(energy.reservedValue0, 800)
            XCTAssertEqual(energy.voltage, 1217787)
            XCTAssertEqual(Float(energy.voltage) / 10_000, 121.7787)
            XCTAssertEqual(Float(energy.amperage) / 10_000, 8.7506)
            XCTAssertEqual(Float(energy.watts) / 10_000, 1039.0168)
            XCTAssertEqual(Float(energy.totalWatts) / 10_000, 0.94)
        }
        
        do {
            let data = Data([0x01, 0x03, 0x20, 0x00, 0x12, 0xA3, 0x95, 0x00, 0x01, 0x58, 0x3E, 0x00, 0x90, 0x9C, 0x9B, 0x00, 0x16, 0x81, 0xB8, 0x00])
            
            guard let notification = PowerWatchdog.NotificationCharacteristic(data: data),
                  case let .energy(energy) = notification else {
                XCTFail()
                return
            }
            
            XCTAssertEqual(energy.reservedValue0, 800)
            XCTAssertEqual(energy.voltage, 1221525)
            XCTAssertEqual(Float(energy.voltage) / 10_000, 122.1525)
            XCTAssertEqual(Float(energy.amperage) / 10_000, 8.8126)
            XCTAssertEqual(Float(energy.watts) / 10_000, 947.7275)
            XCTAssertEqual(Float(energy.totalWatts) / 10_000, 147.5)
        }
    }
    
    func testPowerWatchdogLineNotification() {
        
        let data = Data([0x00, 0x03, 0x70, 0x00, 0x11, 0xAA, 0xF3, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x17, 0x75, 0xE2, 0x2A, 0x00, 0x00, 0x00])
        
        guard let notification = PowerWatchdog.NotificationCharacteristic(data: data),
              case let .line(value) = notification else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(value.line, 0)
        XCTAssertEqual(Float(value.frequency) / 100, 60.05)
    }
}
