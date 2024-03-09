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
}
