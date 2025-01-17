// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GodotSubscription",
    platforms: [
            .iOS(.v17),
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GodotSubscription",
            type: .dynamic,
            targets: ["GodotSubscription"]),
    ],
    dependencies: [
            .package(url: "https://github.com/migueldeicaza/SwiftGodot", branch: "main"),
            .package(url: "https://github.com/RevenueCat/purchases-ios-spm", .upToNextMajor(from: "5.14.6"))
        ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GodotSubscription",
            dependencies: [
                                        "SwiftGodot",
                                        .product(name: "RevenueCat", package: "purchases-ios-spm"),
                                    ],
                                    swiftSettings: [.unsafeFlags(["-suppress-warnings"])]
        ),

    ]
)
