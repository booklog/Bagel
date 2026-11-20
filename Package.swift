// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Bagel",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "Bagel", targets: ["Bagel"])
    ],
    dependencies: [
        .package(url: "https://github.com/robbiehanson/CocoaAsyncSocket.git", .upToNextMajor(from: "7.6.5")),
    ],
    targets: [
        .target(
            name: "Bagel",
            dependencies: ["CocoaAsyncSocket"],
            path: "iOS/Source",
            publicHeadersPath: "."
        )
    ]
)
