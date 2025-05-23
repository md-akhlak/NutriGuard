import SwiftUI

struct MealLogView: View {
    @ObservedObject var userProfile: UserProfile
    @State private var showingAddMeal = false
    @State private var selectedDate = Date()
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredMeals: [MealEntry] {
        userProfile.mealLog.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Date Selector
                DateSelector(selectedDate: $selectedDate)
                    .padding(.horizontal)
                
                if filteredMeals.isEmpty {
                    EmptyMealLogView()
                } else {
                    // Meal Summary
                    MealSummaryCard(meals: filteredMeals)
                        .padding(.horizontal)
                    
                    // Meal List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meals")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ForEach(filteredMeals) { meal in
                            MealLogEntryCard(meal: meal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Meal Log")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddMeal = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
            }
        }
        .sheet(isPresented: $showingAddMeal) {
            AddMealView(userProfile: userProfile, selectedDate: selectedDate)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct DateSelector: View {
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: { moveDate(by: -1) }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text(selectedDate, style: .date)
                    .font(.headline)
                
                Spacer()
                
                Button(action: { moveDate(by: 1) }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            
            // Quick date buttons
            HStack(spacing: 12) {
                QuickDateButton(title: "Today", action: { selectedDate = Date() })
                QuickDateButton(title: "Yesterday", action: { moveDate(by: -1) })
                QuickDateButton(title: "Tomorrow", action: { moveDate(by: 1) })
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func moveDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

struct QuickDateButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}

struct EmptyMealLogView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .blue.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            
            Text("No Meals Logged")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add your meals to track your diet and any reactions")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct MealSummaryCard: View {
    let meals: [MealEntry]
    
    private var totalMeals: Int { meals.count }
    private var hasReactions: Int { meals.filter { !$0.reactions.isEmpty }.count }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Daily Summary")
                .font(.headline)
            
            HStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("\(totalMeals)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Meals")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 8) {
                    Text("\(hasReactions)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(hasReactions > 0 ? .red : .green)
                    
                    Text("Reactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct MealLogEntryCard: View {
    let meal: MealEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(meal.date, style: .time)
                    .font(.headline)
                
                Spacer()
                
                if !meal.reactions.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Reaction")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Text(meal.foodItems.joined(separator: ", "))
                .font(.subheadline)
                .foregroundColor(.primary)
            
            if !meal.reactions.isEmpty {
                Text("Reactions: " + meal.reactions.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            if !meal.notes.isEmpty {
                Text(meal.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

struct AddMealView: View {
    @ObservedObject var userProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    let selectedDate: Date
    
    @State private var foodItems: String = ""
    @State private var reactions: String = ""
    @State private var notes: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text(selectedDate, style: .date)
                        .font(.headline)
                }
                
                Section(header: Text("What did you eat?")) {
                    TextEditor(text: $foodItems)
                        .frame(height: 100)
                }
                
                Section(header: Text("Any reactions?")) {
                    TextEditor(text: $reactions)
                        .frame(height: 100)
                }
                
                Section(header: Text("Additional notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveMeal()
                }
                .disabled(foodItems.isEmpty)
            )
        }
    }
    
    private func saveMeal() {
        let foodItemsList = foodItems
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        let reactionsList = reactions
            .split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }
        
        let entry = MealEntry(
            date: selectedDate,
            foodItems: foodItemsList,
            reactions: reactionsList,
            notes: notes
        )
        
        userProfile.mealLog.append(entry)
        dismiss()
    }
} 