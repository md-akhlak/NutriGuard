//
//  ContentView.swift
//  NutriGuard
//
//  Created by Akhlak iSDP on 22/05/25.
//

import SwiftUI
import VisionKit

struct ContentView: View {
    @EnvironmentObject var userProfile: UserProfile
    @State private var selectedTab = 0
    @StateObject private var menuScannerViewModel: MenuScannerViewModel
    
    init() {
        // Initialize menuScannerViewModel with a temporary UserProfile
        // It will be updated when the view receives the environmentObject
        _menuScannerViewModel = StateObject(wrappedValue: MenuScannerViewModel(userProfile: UserProfile()))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab (Main Screen)
            NavigationView {
                HomeView(userProfile: userProfile)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Menu Analysis Tab
            NavigationView {
                MenuAnalysisView(viewModel: menuScannerViewModel, userProfile: userProfile)
            }
            .tabItem {
                Label("Analysis", systemImage: "chart.bar.fill")
            }
            .tag(1)
            
            // Meal Log Tab
            NavigationView {
                MealLogView(userProfile: userProfile)
            }
            .tabItem {
                Label("Meal Log", systemImage: "list.bullet.clipboard")
            }
            .tag(2)
        }
        .onAppear {
            // Update menuScannerViewModel with the correct userProfile when the view appears
            menuScannerViewModel.updateUserProfile(userProfile)
        }
    }
}


struct EditProfileView: View {
    @ObservedObject var userProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var selectedConditions: Set<MedicalCondition>
    @State private var newRestriction: String = ""
    @State private var additionalRestrictions: [String]
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        _name = State(initialValue: userProfile.name)
        _selectedConditions = State(initialValue: userProfile.medicalConditions)
        _additionalRestrictions = State(initialValue: userProfile.additionalRestrictions)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Name")) {
                    TextField("Your name", text: $name)
                }
                
                Section(header: Text("Medical Conditions")) {
                    ForEach(MedicalCondition.allCases) { condition in
                        Toggle(condition.rawValue.capitalized,
                               isOn: Binding(
                                get: { selectedConditions.contains(condition) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedConditions.insert(condition)
                                    } else {
                                        selectedConditions.remove(condition)
                                    }
                                }
                               ))
                    }
                }
                
                Section(header: Text("Additional Restrictions")) {
                    ForEach(additionalRestrictions, id: \.self) { restriction in
                        Text(restriction)
                    }
                    .onDelete(perform: deleteRestriction)
                    
                    HStack {
                        TextField("Add restriction", text: $newRestriction)
                        Button(action: addRestriction) {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newRestriction.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveProfile()
                }
            )
        }
    }
    
    private func addRestriction() {
        let restriction = newRestriction.trimmingCharacters(in: .whitespaces)
        if !restriction.isEmpty {
            additionalRestrictions.append(restriction)
            newRestriction = ""
        }
    }
    
    private func deleteRestriction(at offsets: IndexSet) {
        additionalRestrictions.remove(atOffsets: offsets)
    }
    
    private func saveProfile() {
        userProfile.name = name
        userProfile.medicalConditions = selectedConditions
        userProfile.additionalRestrictions = additionalRestrictions
        dismiss()
    }
}

#Preview {
    ContentView()
}
