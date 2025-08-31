//
//  LoginView.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import SwiftUI

struct LoginView: View {
    
    @State private var showAlert = false
    @State private var alertMessage: String = ""
    
    @State private var accountId: String = ""
    @State private var password: String = ""
    @State private var selectedOption: String = "nil"
    @State private var pickerOptions = ["nil"]
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("EffnerApp")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            Text("Login")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            VStack(alignment: .leading, spacing: 16) {
                Text("Account ID")
                    .font(.title3)
                TextField("Account ID", text: $accountId)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .autocapitalization(.none)
                Text("Password")
                    .font(.title3)
                SecureField("Password", text: $password)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                Text("Klasse")
                    .font(.title3)
                HStack {
                    Spacer()
                    Picker(selection: $selectedOption, label: Text("Klasse")) {
                        ForEach(pickerOptions, id: \ .self) { option in
                            Text(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    Spacer()
                }
            }
            LoadingButton(action: {
                print("Login tapped with ID: \(accountId), Password: \(password), Option: \(selectedOption)")
                let user = await AuthService().login(username: accountId, password: password, class: selectedOption)
                return user
            }, onResult: { result in
                switch result {
                    case .success(let user):
                        print("Login successful for user: \(user.id)")
                        // User is getting rerouted to the main content view automatically by the App struct
                    case .failure(let error):
                        alertMessage = error.localizedDescription
                        showAlert = true
                }
            }, label: {
                Text("Login")
            })
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Login Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        
        .task {
            await ClassesCache.shared.refreshCache()
            let classes = ClassesCache.shared.cachedClasses
            
            pickerOptions = classes.isEmpty ? pickerOptions : classes
            selectedOption = classes.first ?? "nil"
        }
    }
}

#Preview {
    LoginView()
}
