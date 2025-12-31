import Foundation
import Combine
import AuthenticationServices

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private let userKey = "focusflow_user"
    private let authKey = "focusflow_authenticated"

    struct User: Codable {
        let id: String
        let email: String
        let name: String
        let authMethod: AuthMethod

        enum AuthMethod: String, Codable {
            case apple = "apple"
            case email = "email"
            case google = "google"
        }
    }

    private init() {
        loadAuthState()
    }

    private func loadAuthState() {
        isAuthenticated = UserDefaults.standard.bool(forKey: authKey)

        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
        }
    }

    private func saveAuthState() {
        UserDefaults.standard.set(isAuthenticated, forKey: authKey)

        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
        }
    }

    func signInWithApple(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email ?? "user@icloud.com"
                let name = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                let user = User(
                    id: userID,
                    email: email,
                    name: name.isEmpty ? "Apple User" : name,
                    authMethod: .apple
                )

                currentUser = user
                isAuthenticated = true
                saveAuthState()

                print("✅ Signed in with Apple: \(user.name)")
            }

        case .failure(let error):
            print("❌ Apple Sign In failed: \(error)")
            print("Error details: \(error.localizedDescription)")
        }
    }

    func demoSignInWithApple() {
        let user = User(
            id: UUID().uuidString,
            email: "demo@icloud.com",
            name: "Demo Apple User",
            authMethod: .apple
        )

        currentUser = user
        isAuthenticated = true
        saveAuthState()

        print("✅ Demo signed in with Apple")
    }

    func signInWithEmail(email: String, password: String) -> Bool {
        guard !email.isEmpty, password.count >= 6 else { return false }

        let user = User(
            id: UUID().uuidString,
            email: email,
            name: email.components(separatedBy: "@").first?.capitalized ?? "User",
            authMethod: .email
        )

        currentUser = user
        isAuthenticated = true
        saveAuthState()

        print("✅ Signed in with email: \(user.email)")
        return true
    }

    func signUpWithEmail(email: String, password: String, name: String) -> Bool {
        guard !email.isEmpty, password.count >= 6, !name.isEmpty else { return false }

        let user = User(
            id: UUID().uuidString,
            email: email,
            name: name,
            authMethod: .email
        )

        currentUser = user
        isAuthenticated = true
        saveAuthState()

        print("✅ Signed up with email: \(user.email)")
        return true
    }

    func signInWithGoogle() {
        let user = User(
            id: UUID().uuidString,
            email: "user@gmail.com",
            name: "Google User",
            authMethod: .google
        )

        currentUser = user
        isAuthenticated = true
        saveAuthState()

        print("✅ Signed in with Google (demo)")
    }

    func signOut() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.set(false, forKey: authKey)

        print("✅ Signed out")
    }
}
