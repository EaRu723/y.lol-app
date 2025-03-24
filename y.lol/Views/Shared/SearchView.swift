//
//  SearchView.swift
//  y.lol
//
//  Created by Andrea Russo on 3/24/25.
//

import SwiftUI

struct SearchView: View {
    @Binding var isSearching: Bool
    @State private var searchText: String = ""
    var onSearch: (String) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search conversations...", text: $searchText)
                    .padding(.vertical, 8)
                    .onSubmit {
                        onSearch(searchText)
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                Button(action: {
                    withAnimation {
                        isSearching = false
                    }
                }) {
                    Text("Cancel")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .transition(.move(edge: .top))
    }
}
