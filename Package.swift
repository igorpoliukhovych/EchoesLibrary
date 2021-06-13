// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EchoesLibrary",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "API", targets: ["API"])
    ],
    dependencies: [
        .package(name: "Realm", url: "https://github.com/realm/realm-cocoa.git", from: "10.0.0")
    ],
    targets: [
        .target(name: "API", dependencies: [
                    .product(name: "RealmSwift", package: "Realm")
//                    "RealmSwift", "Realm", "RealmDatabase"
        ]),
        .testTarget(name: "EchoesLibraryTests", dependencies: ["API"])
    ]
)

