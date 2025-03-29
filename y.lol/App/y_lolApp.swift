//
//  y_lolApp.swift
//  y.lol
//
//  Created by Andrea Russo on 2/25/25.
//

import SwiftUI
import Firebase

@main
struct y_lolApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("welcomeShown") var welcomeShown: Bool = true
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView()
                    .preferredColorScheme(.light)
                    .sheet(isPresented: $welcomeShown, content: { OnboardingView(isPresented: $welcomeShown) })
            }
        }
    }
}


