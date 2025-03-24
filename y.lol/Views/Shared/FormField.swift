//
//  FormField.swift
//  y.lol
//
//  Created by Andrea Russo on 3/24/25.
//

import SwiftUI

struct FormField: View {
    @Environment(\.themeColors) private var colors
    
    var title: String
    var placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: UITextAutocapitalizationType = .sentences
    var disableAutocorrection: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(YTheme.Typography.caption)
                .foregroundColor(colors.text(opacity: 0.7))
            
            TextField(placeholder, text: $text)
                .font(YTheme.Typography.body)
                .padding()
                .background(colors.accent.opacity(0.2))
                .cornerRadius(8)
                .foregroundColor(colors.text)
                .keyboardType(keyboardType)
                .autocapitalization(autocapitalization)
                .disableAutocorrection(disableAutocorrection)
        }
        .padding(.horizontal)
    }
}

struct DateField: View {
    @Environment(\.themeColors) private var colors
    
    var title: String
    @Binding var date: Date?
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(YTheme.Typography.caption)
                .foregroundColor(colors.text(opacity: 0.7))
            
            DatePicker(
                "",
                selection: Binding(
                    get: { date ?? Date() },
                    set: { date = $0 }
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
    }
}
