// swift-tools-version:5.9
import PackageDescription

// NOTA: questa macchina ha solo le Command Line Tools (niente Xcode.app), che non
// includono XCTest.framework né il modulo Testing del toolchain. Per poter eseguire
// `swift test` senza Xcode, dichiariamo swift-testing come dipendenza SPM (vendorizza
// le sue sorgenti invece di richiedere il framework di sistema).
let package = Package(
    name: "PuliziaMac",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0")
    ],
    targets: [
        .executableTarget(
            name: "PuliziaMac",
            path: "Sources/PuliziaMac",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "PuliziaMacTests",
            dependencies: [
                "PuliziaMac",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "Tests/PuliziaMacTests"
        )
    ]
)
