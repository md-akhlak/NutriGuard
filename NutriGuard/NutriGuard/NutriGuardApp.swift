//
//  NutriGuardApp.swift
//  NutriGuard
//
//  Created by Akhlak iSDP on 22/05/25.
//

import SwiftUI

@main
struct NutriGuardApp: App {
    @StateObject private var userProfile = UserProfile()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                WelcomeView(userProfile: userProfile)
                    .onDisappear {
                        hasCompletedOnboarding = true
                    }
            } else {
                ContentView()
                    .environmentObject(userProfile)
            }
        }
    }
}
