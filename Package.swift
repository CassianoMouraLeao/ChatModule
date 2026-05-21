// swift-tools-version: 6.0
//
// ChatModule — Swift Package
//
// Lets the chat surface be consumed by other apps (e.g. BTW-ios) as a library.
// The standalone ChatModule.xcodeproj continues to work for iterating on the
// module in isolation — both targets read from the same `ChatModule/` source
// folder.
//

import PackageDescription

let package = Package(
    name: "ChatModule",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "ChatModule",
            targets: ["ChatModule"]
        )
    ],
    dependencies: [
        // Firebase iOS SDK — supplies FirebaseAI (Gemini) and FirebaseRemoteConfig
        // (secret storage). BTW-ios already depends on the same package, so SPM
        // resolves them to a single shared version.
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "12.0.0"
        )
    ],
    targets: [
        .target(
            name: "ChatModule",
            dependencies: [
                .product(name: "FirebaseAI", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk")
            ],
            // Source lives in the existing folder used by the standalone app.
            path: "ChatModule",
            // Skip files that only belong to the standalone app — they would
            // collide with the host app's own entry point if compiled into a
            // library.
            exclude: [
                "ChatModuleApp.swift",
                "ContentView.swift",
                "GoogleService-Info.plist",
                "Assets.xcassets"
            ]
        )
    ]
)
