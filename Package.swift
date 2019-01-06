// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftLisp",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "SwiftLispLib",
            targets: ["SwiftLispLib"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/davedufresne/SwiftParsec", from: "3.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftLispLib",
            dependencies: ["SwiftParsec"],
            path: "Sources/SwiftLisp/SwiftLispLib"
            ),
        .target(
            name: "SwiftLispRepl",
            dependencies: ["SwiftLispLib"],
            path: "Sources/SwiftLisp/SwiftLispRepl"
            ),
        .testTarget(
            name: "SwiftLispTests",
            dependencies: ["SwiftLispLib"])
    ]
)
