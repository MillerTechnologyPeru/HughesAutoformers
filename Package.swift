// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "HughesAutoformers",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
    ],
    products: [
        .library(
            name: "HughesAutoformers",
            targets: ["HughesAutoformers"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            from: "6.0.0"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            from: "3.2.0"
        )
    ],
    targets: [
        .target(
            name: "HughesAutoformers",
            dependencies: [
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                )
            ]
        ),
        .testTarget(
            name: "HughesAutoformersTests",
            dependencies: [
                "HughesAutoformers",
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth",
                    condition: .when(platforms: [.macOS, .linux])
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                )
            ]
        ),
    ]
)
