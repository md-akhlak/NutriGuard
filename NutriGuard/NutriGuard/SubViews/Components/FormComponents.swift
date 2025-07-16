import SwiftUI

struct CustomTextField: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
    }
}

struct SingleDropdownField: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let items: [String]
    @Binding var selectedItem: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Button(action: {
                                selectedItem = item
                                withAnimation {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(item)
                                    Spacer()
                                    if selectedItem == item {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    Text(selectedItem.isEmpty ? "Select \(title)" : selectedItem)
                        .foregroundColor(selectedItem.isEmpty ? .secondary : .primary)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct DropdownField: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let items: [String]
    @Binding var selectedItems: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            DisclosureGroup(
                isExpanded: $isExpanded,
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(items, id: \.self) { item in
                            Button(action: {
                                if selectedItems.contains(item) {
                                    selectedItems.removeAll { $0 == item }
                                } else {
                                    selectedItems.append(item)
                                }
                                withAnimation {
                                    isExpanded = false
                                }
                            }) {
                                HStack {
                                    Text(item)
                                    Spacer()
                                    if selectedItems.contains(item) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding(.top, 8)
                },
                label: {
                    Text(selectedItems.isEmpty ? "Select \(title)" : selectedItems.joined(separator: ", "))
                        .foregroundColor(selectedItems.isEmpty ? .secondary : .primary)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : .white)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct NavigationButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        }
    }
}

struct FormSection<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : .white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )
        }
    }
} 