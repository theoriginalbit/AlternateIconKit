// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "AlternateIconKit",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(name: "AlternateIconKit", targets: ["AlternateIconKit"]),
    ],
    dependencies: [
    ],
    targets: [
        .target( name: "AlternateIconKit", dependencies: []),
    ]
)
