// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "magsafe-charger-stand",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/tomasf/SwiftSCAD.git", branch: "main"),
        .package(url: "https://github.com/tomasf/Helical.git", branch: "main"),
    ],
    targets: [
        .executableTarget(name: "magsafe-charger-stand", dependencies: ["SwiftSCAD", "Helical"])
    ]
)
