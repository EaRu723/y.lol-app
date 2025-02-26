import SwiftUI

struct ProfileDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text("John Doe")
                                .font(.title2)
                                .bold()
                            Text("@johndoe")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    LabeledContent("Email") {
                        Text("john.doe@example.com")
                    }
                    
                    LabeledContent("Member Since") {
                        Text("January 2023")
                    }
                }
                
                Section(header: Text("Preferences")) {
                    Toggle("Dark Mode", isOn: .constant(false))
                    Toggle("Notifications", isOn: .constant(true))
                    Toggle("Newsletter", isOn: .constant(false))
                }
                
                Section(header: Text("Account")) {
                    Button("Edit Profile") {
                        // Action for editing profile
                    }
                    
                    Button("Privacy Settings") {
                        // Action for privacy settings
                    }
                    
                    Button("Log Out") {
                        // Action for logging out
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileDetailView()
} 