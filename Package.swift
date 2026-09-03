// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MDViewer",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "mdviewer", targets: ["MDViewer"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MDViewer",
            dependencies: [],
            path: "Sources/MDViewer",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
