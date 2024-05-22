// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "SwiftLisp",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(
      name: "SwiftLispLib",
      targets: ["SwiftLispLib"]),
    .executable(name: "SwiftLispRepl", targets: ["SwiftLispRepl"]),
  ],
  dependencies: [
    .package(url: "https://github.com/davedufresne/SwiftParsec", from: "4.0.0"),
    .package(url: "https://github.com/apple/swift-testing.git", branch: "main"),
  ],
  targets: [
    .target(
      name: "SwiftLispLib",
      dependencies: ["SwiftParsec"],
      path: "Sources/SwiftLisp/SwiftLispLib"
    ),
    .executableTarget(
      name: "SwiftLispRepl",
      dependencies: ["SwiftLispLib"],
      path: "Sources/SwiftLisp/SwiftLispRepl"
    ),
    .testTarget(
      name: "SwiftLispTest",
      dependencies: [
        "SwiftLispLib",
        .product(name: "Testing", package: "swift-testing"),
      ]
    ),
    // ,
  ]
)
