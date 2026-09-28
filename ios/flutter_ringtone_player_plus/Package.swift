// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "flutter_ringtone_player_plus",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(name: "flutter-ringtone-player-plus", targets: ["flutter_ringtone_player_plus"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_ringtone_player_plus",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: []
        )
    ]
)
