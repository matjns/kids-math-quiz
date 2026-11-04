// swift-tools-version:5.9
import PackageDescription

// The app target needs macOS 14. Linux CI and `swift test` only build the
// logic module; an empty platform list lets that succeed here.
#if os(macOS)
let packagePlatforms: [SupportedPlatform] = [.macOS(.v14)]
#else
let packagePlatforms: [SupportedPlatform]? = nil
#endif

let package = Package(
    name: "MathQuiz",
    platforms: packagePlatforms,
    products: [
        .library(name: "MathQuizCore", targets: ["MathQuizCore"]),
        .executable(name: "MathQuiz", targets: ["MathQuiz"]),
    ],
    targets: [
        .target(name: "MathQuizCore"),
        .executableTarget(
            name: "MathQuiz",
            dependencies: ["MathQuizCore"],
            linkerSettings: [
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
                .linkedFramework("SwiftUI", .when(platforms: [.macOS])),
            ]
        ),
        .testTarget(
            name: "MathQuizCoreTests",
            dependencies: ["MathQuizCore"]
        ),
    ]
)
