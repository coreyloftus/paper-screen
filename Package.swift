// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PaperScreen",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "PaperScreen", path: "Sources/PaperScreen")
    ]
)
