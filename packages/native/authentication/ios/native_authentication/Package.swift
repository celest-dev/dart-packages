// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "native_authentication",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        // Dynamic, like the framework CocoaPods builds with `use_frameworks!`. The
        // FFI bindings look their symbols up in the running process, so they must
        // stay exported and must not be dead-stripped from a static link.
        .library(name: "native-authentication", type: .dynamic, targets: ["native_authentication"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "native_authentication",
            dependencies: [],
            cSettings: [
                .headerSearchPath("include/native_authentication"),
            ],
            linkerSettings: [
                .linkedFramework("AuthenticationServices"),
                .linkedFramework("UIKit"),
            ]
        )
    ]
)
