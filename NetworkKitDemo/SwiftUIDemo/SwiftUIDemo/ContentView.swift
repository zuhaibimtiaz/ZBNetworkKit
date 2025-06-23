//
//  ContentView.swift
//  SwiftUIDemo
//
//  Created by Zuhaib Imtiaz on 09/03/2025.
//

import SwiftUI
import ZBNetworkKit

struct ContentView: View {
    // Fetch users
    @ApiRequest(endpoint: UserEndpoint()) private var users: [User]?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if $users.isLoading {
                    ProgressView("Loading users...")
                } else if let error = $users.error {
                    Text("Users Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                } else if let users = users {
                    List(users, id: \.id) { user in
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("NetworkKit Demo Test")
            .task {
                await $users.fetch() // Fetch users on appear
            }
        }.onAppear {
            ZBNetworkKit.configure(
                .init(
                    baseURL: .init(
                        url: "jsonplaceholder.typicode.com"
                    )
                )
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
