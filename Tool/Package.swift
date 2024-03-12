// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "HughesAutoformersTool",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .executable(
            name: "HughesAutoformersTool",
            targets: ["HughesAutoformersTool"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            from: "6.4.0"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            from: "3.2.0"
        ),
        .package(
            url: "https://github.com/PureSwift/BluetoothLinux.git",
            branch: "master"
        ),
        .package(
            name: "HughesAutoformers",
            path: "../"
        ),
        .package(
            url: "https://github.com/apple/swift-argument-parser.git",
            from: "1.2.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "HughesAutoformersTool",
            dependencies: [
                "HughesAutoformers",
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                ),
                .product(
                    name: "DarwinGATT",
                    package: "GATT",
                    condition: .when(platforms: [.macOS])
                ),
                .product(
                    name: "BluetoothLinux",
                    package: "BluetoothLinux",
                    condition: .when(platforms: [.linux])
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothHCI",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGATT",
                    package: "Bluetooth"
                ),
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                )
            ]
        )
    ]
)
