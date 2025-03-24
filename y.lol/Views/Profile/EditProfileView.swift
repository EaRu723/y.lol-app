//
//  EditProfileView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/24/25.
//


import SwiftUI

struct EditProfileView: View {
    @Environment(\.themeColors) private var colors
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            // Editable name field
            VStack(alignment: .leading) {
                Text("Name")
                    .font(YTheme.Typography.caption)
                    .foregroundColor(colors.text(opacity: 0.7))
                
                TextField("Name", text: $viewModel.editedName)
                    .font(YTheme.Typography.body)
                    .padding()
                    .background(colors.accent.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(colors.text)
            }
            .padding(.horizontal)
            
            // Editable email field
            VStack(alignment: .leading) {
                Text("Email")
                    .font(YTheme.Typography.caption)
                    .foregroundColor(colors.text(opacity: 0.7))
                
                TextField("Email", text: $viewModel.editedEmail)
                    .font(YTheme.Typography.body)
                    .padding()
                    .background(colors.accent.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(colors.text)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal)
            
            // Editable vibe field
            VStack(alignment: .leading) {
                Text("Vibe")
                    .font(YTheme.Typography.caption)
                    .foregroundColor(colors.text(opacity: 0.7))
                
                TextField("What's your vibe?", text: $viewModel.editedVibe)
                    .font(YTheme.Typography.body)
                    .padding()
                    .background(colors.accent.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(colors.text)
            }
            .padding(.horizontal)
            
            // Date of Birth picker
            VStack(alignment: .leading) {
                Text("Date of Birth")
                    .font(YTheme.Typography.caption)
                    .foregroundColor(colors.text(opacity: 0.7))
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { viewModel.editedDateOfBirth ?? Date() },
                        set: { viewModel.editedDateOfBirth = $0 }
                    ),
                    displayedComponents: .date
                )
                .labelsHidden()
                .padding()
                .background(colors.accent.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(colors.text)
            }
            .padding(.horizontal)
            
            // Save/Cancel buttons
            HStack {
                Button(action: {
                    viewModel.cancelEdit()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colors.text)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(colors.accent.opacity(0.3))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    viewModel.saveProfile()
                }) {
                    if viewModel.isSaving {
                        ProgressView()
                            .tint(Color.white)
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(colors.accent)
                .cornerRadius(10)
                .disabled(viewModel.isSaving)
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            if !viewModel.saveError.isEmpty {
                Text(viewModel.saveError)
                    .font(YTheme.Typography.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top, 20)
    }
}
