import SwiftUI

struct ProfileView: View {
    @ObservedObject var userProfile: UserProfile
    @Environment(\.presentationMode) var presentationMode
    @State private var newRestriction = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                profileHeader
                
                // Personal Information
                personalInfoSection
                
                // Medical Conditions
                medicalConditionsSection
                
                // Additional Restrictions
                additionalRestrictionsSection
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Profile")
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
            }
            
            Text(userProfile.name.isEmpty ? "Add Your Name" : userProfile.name)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information")
                .font(.headline)
                .foregroundColor(.secondary)
            
            TextField("Name", text: $userProfile.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
        }
    }
    
    private var medicalConditionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medical Conditions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(MedicalCondition.allCases) { condition in
                    ConditionToggleCard(
                        condition: condition,
                        isSelected: userProfile.medicalConditions.contains(condition),
                        action: {
                            if userProfile.medicalConditions.contains(condition) {
                                userProfile.medicalConditions.remove(condition)
                            } else {
                                userProfile.medicalConditions.insert(condition)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var additionalRestrictionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Restrictions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("Add restriction", text: $newRestriction)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: {
                    if !newRestriction.isEmpty {
                        userProfile.additionalRestrictions.append(newRestriction)
                        newRestriction = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            
            ForEach(userProfile.additionalRestrictions, id: \.self) { restriction in
                HStack {
                    Text(restriction)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        userProfile.additionalRestrictions.removeAll { $0 == restriction }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(10)
            }
        }
    }
}

struct ConditionToggleCard: View {
    let condition: MedicalCondition
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(condition.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(10)
            .animation(.spring(), value: isSelected)
        }
    }
} 