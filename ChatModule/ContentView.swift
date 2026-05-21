//
//  ContentView.swift
//  ChatModule
//
//  Thin wrapper around ChatView so the default Xcode entry point still works
//  if anything else references ContentView. ChatView holds all the UI logic.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ChatView()
    }
}

#Preview {
    ContentView()
}
