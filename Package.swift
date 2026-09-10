// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EnricoPapi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "EnricoPapi", targets: ["EnricoPapi"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EnricoPapi",
            dependencies: [],
            path: "Sources/EnricoPapi"
        )
    ]
)
