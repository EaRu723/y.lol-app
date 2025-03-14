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
    
    var body: some Scene {
        WindowGroup {
            ChatView()
                .preferredColorScheme(.light)
        }
    }
}


