import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthManager.shared

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.45),
                    Color(red: 0.2, green: 0.1, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 32) {
                        // Title
                        VStack(spacing: 12) {
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("Start your focus journey")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.top, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            // Name field
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 24)

                                TextField("Full Name", text: $name)
                                    .textContentType(.name)
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            // Email field
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 24)

                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            // Password field
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 24)

                                SecureField("Password", text: $password)
                                    .textContentType(.newPassword)
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            // Confirm Password field
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(width: 24)

                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .foregroundColor(.white)
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.1))
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )

                            // Sign Up button
                            Button(action: signUp) {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color(red: 0.4, green: 0.8, blue: 1.0),
                                                        Color(red: 0.6, green: 0.4, blue: 1.0)
                                                    ],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                    .shadow(color: Color(red: 0.5, green: 0.6, blue: 1.0).opacity(0.5), radius: 15, y: 8)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 12)
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 24)

                        // Social Sign Up
                        VStack(spacing: 12) {
                            // Sign in with Apple
                            SignInWithAppleButton(
                                onRequest: { request in
                                    request.requestedScopes = [.email, .fullName]
                                },
                                onCompletion: { result in
                                    authManager.signInWithApple(result: result)
                                }
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 56)
                            .cornerRadius(16)

                            // Google Sign In (Placeholder)
                            Button(action: { authManager.signInWithGoogle() }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "g.circle.fill")
                                        .font(.system(size: 24))
                                    Text("Continue with Google")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.15))
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func signUp() {
        // Validation
        guard !name.isEmpty else {
            errorMessage = "Please enter your name"
            showError = true
            return
        }

        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }

        // Sign up
        let success = authManager.signUpWithEmail(email: email, password: password, name: name)
        if success {
            dismiss()
        } else {
            errorMessage = "Failed to create account"
            showError = true
        }
    }
}

#Preview {
    SignUpView()
}
