//
//  NutriGuardApp.swift
//  NutriGuard
//
//  Created by $HahMa on 24/05/25.
//

import SwiftUI

@main
struct NutriGuardApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            if authViewModel.isAuthenticated {
                ContentView()
                    .environmentObject(authViewModel)
            } else {
                AuthView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
