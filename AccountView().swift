//
//  AccountView().swift
//  finance
//
//  Created by Aidana Orazbay on 11/21/25.
//

import SwiftUI
import Foundation
// Views/CategoryBudgetsView.swift
import SwiftUI

struct CategoryBudgetsView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var categoryBudgets: [String: Double] = [:]
    
    let categories = [
        ("Shopping", "cart", Color.orange),
        ("Housing", "house", Color.brown),
        ("Transport", "car", Color.blue),
        ("Food", "fork.knife", Color.green),
        ("Entertainment", "film", Color.pink),
        ("Health", "heart", Color.red),
        ("Subscriptions", "play.tv", Color.purple),
        ("Utilities", "bolt", Color.yellow)
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(categories, id: \.0) { name, icon, color in
                    HStack {
                        Image(systemName: icon)
                            .foregroundColor(.white)
                            .frame(width: 30, height: 30)
                            .background(color)
                            .cornerRadius(6)
                        
                        Text(name)
                            .font(.headline)
                        
                        Spacer()
                        
                        TextField("0.00", text: Binding(
                            get: {
                                String(format: "%.2f", categoryBudgets[name] ?? 0)
                            },
                            set: { newValue in
                                if let value = Double(newValue) {
                                    categoryBudgets[name] = value
                                } else if newValue.isEmpty {
                                    categoryBudgets[name] = 0
                                }
                            }
                        ))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Category Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCategoryBudgets()
                    }
                }
            }
            .onAppear {
                // Load existing category budgets
                loadCategoryBudgets()
            }
        }
    }
    
    private func loadCategoryBudgets() {
        // In a real app, you'd load from UserDefaults or backend
        // For now, we'll initialize with zeros
        for category in categories {
            categoryBudgets[category.0] = 0
        }
    }
    
    private func saveCategoryBudgets() {
        // Save category budgets to UserDefaults
        UserDefaults.standard.set(categoryBudgets, forKey: "categoryBudgets")
    }
}
// Models/User.swift
import Foundation
// Views/CurrencySettingsView.swift
struct BudgetSettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var monthlyBudget: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Monthly Budget")) {
                    HStack {
                        Text("Amount")
                        
                        Spacer()
                        
                        TextField("0.00", text: $monthlyBudget)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }
                
                Section(header: Text("Budget Categories"), footer: Text("Set monthly spending limits for different categories to help manage your finances.")) {
                    NavigationLink("Category Budgets") {
                        CategoryBudgetsView()
                            .environmentObject(authManager)
                    }
                }
                
                Section(header: Text("Budget Alerts")) {
                    Toggle("Over Budget Notifications", isOn: Binding(
                        get: { authManager.currentUser?.notificationsEnabled ?? true },
                        set: { newValue in
                            if var user = authManager.currentUser {
                                user.notificationsEnabled = newValue
                                authManager.updateProfile(user)
                            }
                        }
                    ))
                }
            }
            .navigationTitle("Budget Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBudget()
                    }
                    .disabled(monthlyBudget.isEmpty || Double(monthlyBudget) == nil)
                }
            }
            .onAppear {
                if let budget = authManager.currentUser?.monthlyBudget {
                    monthlyBudget = String(format: "%.2f", budget)
                }
            }
        }
    }
    
    private func saveBudget() {
        guard let budgetAmount = Double(monthlyBudget) else { return }
        
        if var user = authManager.currentUser {
            user.monthlyBudget = budgetAmount
            authManager.updateProfile(user)
            dismiss()
        }
    }
}

struct CurrencySettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    let currencies = [
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("JPY", "Japanese Yen", "¥"),
        ("CAD", "Canadian Dollar", "C$"),
        ("AUD", "Australian Dollar", "A$"),
        ("CNY", "Chinese Yuan", "¥"),
        ("KZT", "Kazakhstani Tenge", "₸")
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Select Currency")) {
                    ForEach(currencies, id: \.0) { code, name, symbol in
                        Button(action: {
                            updateCurrency(code)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(code)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(symbol)
                                    .font(.title3)
                                    .foregroundColor(.primary)
                                
                                if authManager.currentUser?.currency == code {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                
                Section(footer: Text("Changing currency will not convert existing transaction amounts. This only affects how amounts are displayed.")) {
                    // Footer text
                }
            }
            .navigationTitle("Currency")
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
    
    private func updateCurrency(_ currencyCode: String) {
        if var user = authManager.currentUser {
            user.currency = currencyCode
            authManager.updateProfile(user)
        }
    }
}
struct User: Codable {
    var id: UUID = UUID()
    var email: String
    var firstName: String
    var lastName: String
    var currency: String = "USD"
    var monthlyBudget: Double = 0.0
    var notificationsEnabled: Bool = true
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
// Views/RegisterView.swift
import SwiftUI

struct RegisterView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    
    var passwordsMatch: Bool {
        !password.isEmpty && password == confirmPassword
    }
    
    var isFormValid: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        passwordsMatch
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                }
                
                Section(header: Text("Account Information")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                    
                    if !password.isEmpty && !confirmPassword.isEmpty && !passwordsMatch {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button(action: register) {
                        if authManager.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Account")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || authManager.isLoading)
                    .foregroundColor(.white)
                    .listRowBackground(isFormValid ? Color.blue : Color.gray)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func register() {
        errorMessage = nil
        authManager.register(
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password
        ) { success, error in
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Registration failed"
            }
        }
    }
}
// Managers/AuthManager.swift
import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    
    // Mock user for demo (in real app, this would come from backend)
    private let mockUser = User(
        email: "john@example.com",
        firstName: "John",
        lastName: "Doe",
        currency: "USD",
        monthlyBudget: 3000.0
    )
    
    init() {
        // Check if user is already logged in (from UserDefaults)
        checkExistingUser()
    }
    
    private func checkExistingUser() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isLoggedIn = true
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            
            // Mock validation
            if email == "john@example.com" && password == "password" {
                self.currentUser = self.mockUser
                self.isLoggedIn = true
                
                // Save to UserDefaults
                if let userData = try? JSONEncoder().encode(self.mockUser) {
                    UserDefaults.standard.set(userData, forKey: "currentUser")
                }
                
                completion(true, nil)
            } else {
                completion(false, "Invalid email or password")
            }
        }
    }
    
    func register(firstName: String, lastName: String, email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        isLoading = true
        
        // Simulate API call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            
            // Mock registration
            let newUser = User(
                email: email,
                firstName: firstName,
                lastName: lastName,
                currency: "USD",
                monthlyBudget: 0.0
            )
            
            self.currentUser = newUser
            self.isLoggedIn = true
            
            // Save to UserDefaults
            if let userData = try? JSONEncoder().encode(newUser) {
                UserDefaults.standard.set(userData, forKey: "currentUser")
            }
            
            completion(true, nil)
        }
    }
    
    func updateProfile(_ user: User) {
        currentUser = user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
    
    func logout() {
        currentUser = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }
}

// Views/LoginView.swift
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email: String = "john@example.com"
    @State private var password: String = "password"
    @State private var showingRegister = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                            
                            Text("Finance Assistant")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Manage your finances with ease")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            // Error Message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            
                            // Login Button
                            Button(action: login) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Login")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .disabled(authManager.isLoading)
                        }
                        .padding(.horizontal, 30)
                        
                        // Register Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            Button("Register") {
                                showingRegister = true
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingRegister) {
                RegisterView()
                    .environmentObject(authManager)
            }
        }
    }
    
    private func login() {
        errorMessage = nil
        authManager.login(email: email, password: password) { success, error in
            if !success {
                errorMessage = error ?? "Login failed"
            }
        }
    }
}
// Views/EditProfileView.swift
import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty)
                }
            }
            .onAppear {
                if let user = authManager.currentUser {
                    firstName = user.firstName
                    lastName = user.lastName
                    email = user.email
                }
            }
        }
    }
    
    private func saveProfile() {
        if var user = authManager.currentUser {
            user.firstName = firstName
            user.lastName = lastName
            user.email = email
            authManager.updateProfile(user)
            dismiss()
        }
    }
}
// Views/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dataManager: SharedDataManager
    @State private var showingEditProfile = false
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Text(authManager.currentUser?.firstName.prefix(1).uppercased() ?? "?")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.fullName ?? "User")
                                .font(.headline)
                            
                            Text(authManager.currentUser?.email ?? "email@example.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                        
                        Spacer()
                        
                        Button("Edit") {
                            showingEditProfile = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
                
                // Statistics Section
                Section(header: Text("Statistics")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Transactions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(dataManager.transactions.count)")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Monthly Budget")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(authManager.currentUser?.monthlyBudget ?? 0, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // Settings Section
                Section(header: Text("Settings")) {
                    NavigationLink("Currency Settings") {
                        CurrencySettingsView()
                            .environmentObject(authManager)
                    }
                    
                    NavigationLink("Budget Settings") {
                        BudgetSettingsView()
                            .environmentObject(authManager)
                    }
                    
                    Toggle("Notifications", isOn: Binding(
                        get: { authManager.currentUser?.notificationsEnabled ?? true },
                        set: { newValue in
                            if var user = authManager.currentUser {
                                user.notificationsEnabled = newValue
                                authManager.updateProfile(user)
                            }
                        }
                    ))
                }
                
                // Account Section
                Section {
                    Button("Log Out", role: .destructive) {
                        showingLogoutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView()
                    .environmentObject(authManager)
            }
            .alert("Log Out", isPresented: $showingLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    authManager.logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
    }
}

#Preview {
    EmptyView()
}
