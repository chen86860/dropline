// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Dropline",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Dropline",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/Dropline",
            linkerSettings: [
                // Sparkle.framework 由 build.sh 拷进 Contents/Frameworks
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])
            ]
        )
    ]
)
