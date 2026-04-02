//
//  LoginView.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var classes: ClassesCache
    
    @State private var loginFailed = false
    @State private var errorMessage: String = ""
    
    @State private var accountId: String = ""
    @State private var password: String = ""
    @State private var selectedOption: String = "null"
    @State private var pickerOptions = ["null"]
    
    @AppStorage("hasSeenOnBoarding") private var hasSeenOnBoarding = false
    @State private var showingLegalInfo = false
    @State private var showingOnBoarding = false
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case accountId, password
    }
    
    var body: some View {
        NavigationStack {
        GeometryReader { geometry in
            VStack(spacing: focusedField != nil ? 8 : 20) {
                if focusedField == nil {
                    Spacer()
                }
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: focusedField != nil ? 48 : 120,
                        height: focusedField != nil ? 48 : 120
                    )
                    .padding(.top, focusedField != nil ? 8 : 0)
                Text("EffnerApp")
                    .font(focusedField != nil ? .title3 : .largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Account ID")
                        .font(.title3)
                    TextField("Account ID", text: $accountId)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(loginFailed ? Color.red : Color.clear, lineWidth: 2)
                        )
                        .autocapitalization(.none)
                        .submitLabel(.done)
                        .focused($focusedField, equals: .accountId)
                        .onChange(of: accountId) { loginFailed = false }
                    Text("Passwort")
                        .font(.title3)
                    SecureField("Passwort", text: $password)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(loginFailed ? Color.red : Color.clear, lineWidth: 2)
                        )
                        .submitLabel(.done)
                        .focused($focusedField, equals: .password)
                        .onChange(of: password) { loginFailed = false }
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
                if loginFailed {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
                LoadingButton(action: {
                    print("Login tapped with Username: \(accountId), Password: \(password), Option: \(selectedOption)")
                    let user = await AuthService().register(username: accountId, password: password, klasses: [selectedOption])
                    return user
                }, onResult: { result in
                    switch result {
                        case .success(let user):
                            print("Login successful for user: \(user.username)")
                            // User is getting rerouted to the main content view automatically by the App struct
                        case .failure(let error):
                            withAnimation {
                                errorMessage = error.localizedDescription
                                loginFailed = true
                            }
                    }
                }, label: {
                    Text("Anmeldung")
                })
                    .padding(.top, 8)
                Spacer()
                Button(action: {
                    showingLegalInfo = true
                }) {
                    Text("Impressum & Datenschutzerklärung")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .animation(.easeInOut(duration: 0.3), value: focusedField)
        }
        .ignoresSafeArea(.keyboard)
        .onSubmit {
            focusedField = nil
        }
        .onTapGesture {
            focusedField = nil
        }
        .sheet(isPresented: $showingLegalInfo) {
            LegalInfoView()
        }
        .sheet(isPresented: $showingOnBoarding, onDismiss: {
            hasSeenOnBoarding = true
        }) {
            OnBoardingView()
        }
        .onAppear {
            if !hasSeenOnBoarding {
                showingOnBoarding = true
            }
        }
        .navigationTitle("Anmelden")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    showingOnBoarding = true
                }) {
                    Image(systemName: "info.circle")
                }
            }
        }
        }
        .task {
            await classes.refreshCache()
            
            pickerOptions = classes.cachedClasses.isEmpty ? pickerOptions : classes.cachedClasses
            selectedOption = classes.cachedClasses.first ?? "null"
        }
    }
}

#Preview {
    let mockCache = ClassesCache()
    mockCache.saveClasses(["5a", "5b", "6a", "6b", "7a", "7b"])
    return LoginView()
        .environmentObject(mockCache)
}
