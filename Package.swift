// swift-tools-version: 5.7

import PackageDescription

let env = Context.environment["ALLUI_ENV"]

let dependencies: [Package.Dependency]
if env == "LOCAL" {
    dependencies = [.package(name: "DocumentUI", path: "../DocumentUI")]
} else {
    dependencies = [.package(url: "https://github.com/Everything-as-UI/DocumentUI.git", branch: "main")]
}

let package = Package(
    name: "SwiftLangUI",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "SwiftLangUI", targets: ["SwiftLangUI"])
    ],
    dependencies: dependencies,
    targets: [
        .target(name: "SwiftLangUI", dependencies: ["DocumentUI"]),
        .testTarget(name: "SwiftLangUITests", dependencies: ["SwiftLangUI"])
    ]
)
