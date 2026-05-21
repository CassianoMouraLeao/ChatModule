//
//  Secrets.swift
//  ChatModule
//
//  Fetches API tokens from Firebase Remote Config so they never live in the
//  app bundle nor in source control. The flow:
//
//      App launch  →  Secrets.bootstrap()  →  fetchAndActivate from Firebase
//                                                  ↓
//                              token cached in disk + memory
//                                                  ↓
//                       OpenAIService reads Secrets.githubModelsToken
//
//  Caching behaviour:
//      • Once fetched, the value is persisted to disk by the Firebase SDK.
//      • Subsequent launches read the cached value instantly, even offline.
//      • A fresh fetch runs in the background on launch (Debug: every launch;
//        Release: every 12h) so rotating the token in Firebase Console
//        propagates without re-releasing the app.
//
//  Security note: this is BETTER than bundling secrets, but NOT bulletproof —
//  a determined attacker with MITM on a jailbroken device can still see the
//  token in the Remote Config response. For real production, proxy through
//  Cloud Functions so the token never reaches the client.
//

import Foundation
import FirebaseRemoteConfig

nonisolated enum Secrets {

    // MARK: - Keys

    /// Parameter keys defined in Firebase Console → Remote Config.
    private enum Key {
        static let githubModelsToken = "GITHUB_MODELS_TOKEN"
    }

    // MARK: - RemoteConfig singleton

    private static let remoteConfig: RemoteConfig = {
        let rc = RemoteConfig.remoteConfig()
        // Defaults are used before the first successful fetch. Empty string
        // makes OpenAIService throw a clear "missing API key" error rather
        // than sending a bogus request.
        rc.setDefaults([Key.githubModelsToken: "" as NSObject])
        return rc
    }()

    // MARK: - Bootstrap

    /// Call once on app launch, after FirebaseApp.configure().
    /// Pulls the latest values from Remote Config and activates them.
    /// Safe to await — non-throwing; any error is logged.
    static func bootstrap() async {
        // Fetch cadence:
        //   DEBUG   → fetch on every launch (instant feedback while iterating)
        //   RELEASE → cache for 12h (Firebase rate-limits aggressive fetches)
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 43_200 // 12 hours
        #endif
        remoteConfig.configSettings = settings

        do {
            try await remoteConfig.fetchAndActivate()
        } catch {
            // Don't crash — disk-cached values (from a previous launch) are
            // still readable. If even that is empty, the UI will surface the
            // error when the user tries to send a message.
            print("[Secrets] Remote Config fetch failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Tokens

    /// GitHub Personal Access Token with the `models:read` scope, used by
    /// OpenAIService to hit https://models.github.ai/inference.
    /// Set in Firebase Console → Build → Remote Config → parameter
    /// `GITHUB_MODELS_TOKEN`.
    static var githubModelsToken: String? {
        let value = remoteConfig.configValue(forKey: Key.githubModelsToken).stringValue
        // Treat empty string as "not configured" so callers can show a clean error.
        return value.isEmpty ? nil : value
    }
}
