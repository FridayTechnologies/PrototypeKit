// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PrototypeKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PrototypeKit",
            targets: ["PrototypeKit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PrototypeKit",
            resources: [
                // Ship the privacy manifest inside the library's resource bundle so apps that
                // embed PrototypeKit inherit an accurate App Store privacy report.
                .copy("PrivacyInfo.xcprivacy")
            ]),
        .testTarget(
            name: "PrototypeKitTests",
            dependencies: ["PrototypeKit"],
        resources: [
            .embedInCode("Resources"),
        ]),
    ]
)
