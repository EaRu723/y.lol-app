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
        ZStack {
            colors.backgroundWithNoise
                .ignoresSafeArea()
            
            VStack {
                // Header
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(colors.text)
                    }
                    
                    Spacer()
                    
                    Text("Edit Profile")
                        .font(YTheme.Typography.subtitle)
                        .foregroundColor(colors.text)
                    
                    Spacer()
                    
                    // Save button
                    Button(action: {
                        viewModel.saveProfile()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save")
                            .font(YTheme.Typography.body)
                            .foregroundColor(colors.text)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
                
                // Edit form content
                ScrollView {
                    VStack(spacing: 30) {
                        // Add emoji picker at the top
                        EmojiPicker(selectedEmoji: $viewModel.editedEmoji)
                            .padding(.horizontal)
                        
                        // Form fields
                        FormField(
                            title: "Name",
                            placeholder: "Name",
                            text: $viewModel.editedName
                        )
                        
                        FormField(
                            title: "Email",
                            placeholder: "Email",
                            text: $viewModel.editedEmail,
                            keyboardType: .emailAddress,
                            autocapitalization: .none,
                            disableAutocorrection: true
                        )
                        
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
                    }
                    .padding()
                }
            }
        }
        .withYTheme()
    }
}
