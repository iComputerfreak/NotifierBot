// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Notifier",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .executable(
            name: "Notifier",
            targets: ["Notifier"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/givip/Telegrammer", .exact("1.0.0-alpha.4.0.1")),
        .package(name: "Shared", path: "../Shared")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Notifier",
            dependencies: ["Telegrammer", "Shared"]),
        .testTarget(
            name: "NotifierTests",
            dependencies: ["Notifier"]),
    ]
)
