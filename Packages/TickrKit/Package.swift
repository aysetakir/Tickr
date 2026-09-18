// swift-tools-version: 6.2

import PackageDescription

// Uygulamanın Xcode'dan bağımsız tüm mantığı bu pakette yaşar.
// Her modül ayrı bir target: bağımlılık yönü burada açıkça görünür ve
// yanlış yöne import (ör. MarketCore → Courier) derlenmez.
//
// macOS da listede, çünkü UI içermeyen modüller `swift test` ile
// simülatör açmadan test edilebilsin.
let package = Package(
    name: "TickrKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MarketCore", targets: ["MarketCore"]),
        .library(name: "MarketAPI", targets: ["MarketAPI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/aysetakir/Courier.git", from: "1.0.0"),
    ],
    targets: [
        // Saf modeller ve protokoller. Hiçbir şeye bağımlı değil.
        .target(name: "MarketCore"),

        // Binance REST uçları. Courier'i yalnızca bu modül bilir.
        .target(
            name: "MarketAPI",
            dependencies: [
                "MarketCore",
                .product(name: "Courier", package: "Courier"),
            ]
        ),

        .testTarget(name: "MarketCoreTests", dependencies: ["MarketCore"]),
    ]
)
