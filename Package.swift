// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimHack",
    products: [
        .library(
            name: "SimHack",
            targets: ["SimHack"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SimHack",
            dependencies: []),
        .testTarget(
            name: "SimHackTests",
            dependencies: ["SimHack"]),
    ]
)
