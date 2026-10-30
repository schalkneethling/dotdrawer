// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dotdrawer",
    platforms: [
        .macOS(.v14),
    ],
    targets: [
        // UI-free logic: which dotfiles exist and which ones the user chose.
        .target(
            name: "DotdrawerCore",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        // The menu bar app itself.
        .executableTarget(
            name: "dotdrawer",
            dependencies: ["DotdrawerCore"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "DotdrawerCoreTests",
            dependencies: ["DotdrawerCore"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
