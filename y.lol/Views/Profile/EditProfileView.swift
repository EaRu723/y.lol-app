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
            // Add emoji picker at the top
            EmojiPicker(selectedEmoji: $viewModel.editedEmoji)
                .padding(.horizontal)
            
            // Editable name field
            FormField(
                title: "Name",
                placeholder: "Name",
                text: $viewModel.editedName
            )
            
            // Editable email field
            FormField(
                title: "Email",
                placeholder: "Email",
                text: $viewModel.editedEmail,
                keyboardType: .emailAddress,
                autocapitalization: .none,
                disableAutocorrection: true
            )
            
            // Editable vibe field
            FormField(
                title: "Vibe",
                placeholder: "What's your vibe?",
                text: $viewModel.editedVibe
            )
            
            // Date of Birth picker
            DateField(
                title: "Date of Birth",
                date: $viewModel.editedDateOfBirth
            )
            
            // Save/Cancel buttons
            HStack {
                YButton(
                    title: "Cancel", 
                    isPrimary: false, 
                    action: {
                        viewModel.cancelEdit()
                    }
                )
                
                YButton(
                    title: "Save",
                    isLoading: viewModel.isSaving,
                    action: {
                        viewModel.saveProfile()
                    }
                )
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
        .background(Color.white)
    }
}
