// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dropline",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Dropline",
            path: "Sources/Dropline"
        )
    ]
)
