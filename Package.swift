// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GasGridManager",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "GasGridManager", targets: ["GasGridManager"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "GasGridManager",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "GasGridManagerTests",
            dependencies: [
                "GasGridManager",
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "Tests/GasGridManagerTests"
        ),
    ]
)
