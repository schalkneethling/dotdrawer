// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "dotdrawer",
    platforms: [
        // Keep in step with LSMinimumSystemVersion in Resources/Info.plist,
        // which build-app.sh and update-cask.sh read.
        .macOS(.v26),
    ],
    dependencies: [
        // In-app updates. Pinned to an exact release, because it ships inside
        // the app and verifies every update it installs.
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
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
            dependencies: [
                "DotdrawerCore",
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
            linkerSettings: [
                // build-app.sh puts Sparkle.framework in Contents/Frameworks.
                // The default @loader_path still covers `swift run`, where the
                // framework sits next to the binary.
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
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
