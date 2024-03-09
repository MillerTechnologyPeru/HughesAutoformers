//
//  Hexadecimal.swift
//  
//
//  Created by Alsey Coleman Miller on 3/9/24.
//

import Foundation

internal extension FixedWidthInteger {
    
    func toHexadecimal() -> String {
        
        var string = String(self, radix: 16)
        while string.utf8.count < (MemoryLayout<Self>.size * 2) {
            string = "0" + string
        }
        return string.uppercased()
    }
}

internal extension Collection where Element: FixedWidthInteger {
    
    func toHexadecimal() -> String {
        let length = count * MemoryLayout<Element>.size * 2
        var string = ""
        string.reserveCapacity(length)
        string = reduce(into: string) { $0 += $1.toHexadecimal() }
        assert(string.count == length)
        return string
    }
}

internal extension Data {
    
    init?(hexadecimal string: String) {
        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
        func decodeNibble(_ u: UInt16) -> UInt8? {
            switch(u) {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }
        
        let str: String
        if (string.prefix(2).uppercased() == "0X") {
            str = String(string.suffix(from: string.index(string.startIndex, offsetBy: 2)))
        } else {
            str = string
        }
        let utf16: String.UTF16View
        if (str.count % 2 == 1) {
            utf16 = ("0" + str).utf16
        } else {
            utf16 = str.utf16
        }
        var data = Data(capacity: utf16.count/2)
        
        var i = utf16.startIndex
        while i != utf16.endIndex {
            guard let hi = decodeNibble(utf16[i]),
                  let nxt = utf16.index(i, offsetBy:1, limitedBy: utf16.endIndex),
                  let lo = decodeNibble(utf16[nxt])
            else {
                return nil
            }
#if os(Linux)
            var value = hi << 4 + lo
            let buffer = UnsafeBufferPointer(start: &value, count:1)
            data.append(buffer)
#else
            let value = hi << 4 + lo
            data.append(value)
#endif
            
            guard let next = utf16.index(i, offsetBy:2, limitedBy: utf16.endIndex) else {
                break
            }
            i = next
        }
        
        self = data
        
    }
}
