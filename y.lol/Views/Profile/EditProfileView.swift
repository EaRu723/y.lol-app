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
                        // Profile Picture Section
                        VStack(spacing: 12) {
                            if let image = viewModel.selectedProfileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let url = viewModel.profilePictureUrl {
                                AsyncImage(url: URL(string: url)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Text(viewModel.editedEmoji)
                                        .font(.system(size: 80))
                                }
                            } else {
                                Text(viewModel.editedEmoji)
                                    .font(.system(size: 80))
                            }
                            
                            PhotosPickerView(
                                selectedImage: $viewModel.selectedProfileImage,
                                selectedImageUrl: $viewModel.profilePictureUrl,
                                isPresented: .constant(false)
                            )
                            .padding(.top, 8)
                        }
                        
                        // Divider between photo and emoji sections
                        Divider()
                            .padding(.vertical, 8)
                        
                        // Existing emoji picker and form fields
                        Text("Or choose an emoji")
                            .font(YTheme.Typography.caption)
                            .foregroundColor(colors.text(opacity: 0.7))
                        
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
