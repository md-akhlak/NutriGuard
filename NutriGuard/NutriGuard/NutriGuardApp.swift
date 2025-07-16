//
//  NutriGuardApp.swift
//  NutriGuard
//
//  Created by $HahMa on 24/05/25.
//

import SwiftUI

@main
struct NutriGuardApp: App {
    init() {
        // Ensure a user profile exists at launch
        if UserProfileManager.shared.userProfile == nil {
            UserProfileManager.shared.setupDefaultProfile()
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
