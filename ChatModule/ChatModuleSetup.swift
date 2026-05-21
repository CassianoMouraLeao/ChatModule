//
//  ChatModuleSetup.swift
//  ChatModule
//
//  Public entry point for host apps to bootstrap the module.
//  BTW-ios (and any other consumer) calls `await ChatModuleSetup.bootstrap()`
//  from its AppDelegate / @main App after Firebase has been configured.
//

import Foundation

public enum ChatModuleSetup {

    /// Fetches API tokens from Firebase Remote Config so the OpenAI service
    /// can hit GitHub Models without a key in the bundle.
    ///
    /// Pre-conditions:
    ///   • FirebaseApp.configure() has already been called by the host app.
    ///   • The host's Firebase project has Remote Config + AI Logic enabled.
    public static func bootstrap() async {
        await Secrets.bootstrap()
    }
}
