import Foundation
import Supabase
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

enum AuthProvider: String {
    case apple = "apple"
    case google = "google"
    case email = "email"
}

@MainActor
final class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var authProvider: AuthProvider?

    private var deleteAccountNonce: String?
    private var pendingDeleteContinuation: CheckedContinuation<String, Error>?

    private let client: SupabaseClient
    private var appleNonce: String?
    private var pendingAppleContinuation: CheckedContinuation<Void, Error>?

    private override init() {
        self.client = SupabaseConfig.shared.client
        super.init()
    }

    // MARK: - Session

    func restoreSession() async {
        do {
            let session = try await client.auth.session
            await loadProfile(userId: session.user.id.uuidString, email: session.user.email ?? "")

            // Detect auth provider
            if session.user.appMetadata["provider"] as? String == "apple" {
                self.authProvider = .apple
            } else if session.user.appMetadata["provider"] as? String == "google" {
                self.authProvider = .google
            } else {
                self.authProvider = .email
            }

            self.isAuthenticated = true
        } catch {
            self.isAuthenticated = false
            self.currentUser = nil
            self.authProvider = nil
        }
    }

    // MARK: - Email/Password

    func signUpWithEmail(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            let user = response.user
            try await createProfile(userId: user.id.uuidString, email: email, displayName: displayName)
            await loadProfile(userId: user.id.uuidString, email: email)
            self.isAuthenticated = true
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    func signInWithEmail(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            await loadProfile(userId: session.user.id.uuidString, email: session.user.email ?? email)
            self.isAuthenticated = true
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    // MARK: - Apple Sign In

    func signInWithApple(presentationContext: ASPresentationAnchor) async throws {
        let nonce = Self.randomNonceString()
        self.appleNonce = nonce
        let hashedNonce = Self.sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.pendingAppleContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle(presenting: UIViewController) async throws {
        if GIDSignIn.sharedInstance.configuration == nil, !AppConfig.googleClientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppConfig.googleClientID)
        }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.authFailed("Could not obtain Google ID token.")
            }
            let accessToken = result.user.accessToken.tokenString
            let session = try await client.auth.signInWithIdToken(
                credentials: .init(provider: .google, idToken: idToken, accessToken: accessToken)
            )
            let email = session.user.email ?? result.user.profile?.email ?? ""
            let displayName = result.user.profile?.name
            try? await ensureProfileExists(userId: session.user.id.uuidString, email: email, displayName: displayName)
            await loadProfile(userId: session.user.id.uuidString, email: email)
            self.isAuthenticated = true
        } catch {
            print("🔴 Google Sign-in Error: \(error)")
            throw SupabaseErrorMapper.map(error)
        }
    }

    // MARK: - Re-authentication

    func reauthenticateWithApple(presentationContext: ASPresentationAnchor) async throws -> String {
        let nonce = Self.randomNonceString()
        self.deleteAccountNonce = nonce
        let hashedNonce = Self.sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = hashedNonce

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            self.pendingDeleteContinuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func reauthenticateWithGoogle(presenting: UIViewController) async throws -> String {
        if GIDSignIn.sharedInstance.configuration == nil, !AppConfig.googleClientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: AppConfig.googleClientID)
        }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
            guard let idToken = result.user.idToken?.tokenString else {
                throw AppError.authFailed("Could not obtain Google ID token.")
            }
            return idToken
        } catch {
            print("🔴 Google re-authentication error: \(error)")
            throw SupabaseErrorMapper.map(error)
        }
    }

    func validateEmailPassword(_ password: String) async throws {
        guard let email = currentUser?.email else { throw AppError.notAuthenticated }
        do {
            _ = try await client.auth.signIn(email: email, password: password)
        } catch {
            throw AppError.authFailed("Incorrect password.")
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        do {
            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            throw SupabaseErrorMapper.map(error)
        }
    }

    // MARK: - Delete Account

    func deleteAccount(
        withAppleIDToken idToken: String? = nil,
        googleIDToken: String? = nil,
        emailPassword: String? = nil
    ) async throws {
        guard let userId = currentUser?.id else { throw AppError.notAuthenticated }
        guard let session = try? await client.auth.session else { throw AppError.notAuthenticated }

        let jwt = session.accessToken

        struct DeleteAccountPayload: Encodable {
            let userId: String
            let appleIDToken: String?
            let googleIDToken: String?
            let emailPassword: String?
        }

        do {
            let response = try await client.functions.invoke(
                "delete-account",
                options: FunctionInvokeOptions(
                    headers: ["Authorization": "Bearer \(jwt)"],
                    body: DeleteAccountPayload(
                        userId: userId,
                        appleIDToken: idToken,
                        googleIDToken: googleIDToken,
                        emailPassword: emailPassword
                    )
                )
            )

            try await client.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            self.authProvider = nil
        } catch {
            print("🔴 AuthService.deleteAccount failed: \(error)")
            throw SupabaseErrorMapper.map(error)
        }
    }

    // MARK: - Profile management

    private func createProfile(userId: String, email: String, displayName: String) async throws {
        let insert = UserProfileInsert(
            id: userId,
            email: email,
            display_name: displayName.isEmpty ? nil : displayName,
            plan_tier: PlanTier.free.rawValue
        )
        try await client.from("profiles").upsert(insert).execute()
    }

    private func ensureProfileExists(userId: String, email: String, displayName: String?) async throws {
        let insert = UserProfileInsert(
            id: userId,
            email: email,
            display_name: displayName,
            plan_tier: PlanTier.free.rawValue
        )
        do {
            try await client.from("profiles").upsert(insert, onConflict: "id").execute()
            print("🟢 AuthService: Successfully ensured profile exists in Supabase.")
        } catch {
            print("🔴 AuthService.ensureProfileExists failed: \(error)")
            throw error
        }
    }

    private func loadProfile(userId: String, email: String) async {
        do {
            let row: UserProfileDTO = try await client
                .from("profiles")
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value

            let profile = UserProfile(
                id: row.id,
                email: row.email,
                displayName: row.display_name,
                planTier: PlanTier(rawValue: row.plan_tier) ?? .free,
                checkInStreak: row.check_in_streak,
                lastCheckInDate: row.last_check_in_date,
                totalCheckIns: row.total_check_ins,
                reminderEnabled: row.reminder_enabled,
                reminderTime: row.reminder_time,
                createdAt: row.created_at
            )
            self.currentUser = profile
            print("🟢 AuthService: Successfully loaded profile from Supabase for \(email). Display name: \(row.display_name ?? "nil")")
        } catch {
            print("🔴 AuthService.loadProfile failed: \(error). Falling back to synthesized local profile.")
            // Fallback: synthesize a local profile so the app still loads.
            self.currentUser = UserProfile(id: userId, email: email)
        }
    }

    // MARK: - Updates

    func updateDisplayName(_ name: String) async {
        guard let userId = currentUser?.id else { return }
        var update = UserProfileUpdate()
        update.display_name = name
        do {
            try await client.from("profiles").update(update).eq("id", value: userId).execute()
            currentUser?.displayName = name
            print("🟢 AuthService: Successfully updated display name to '\(name)' in Supabase.")
        } catch {
            print("🔴 AuthService.updateDisplayName failed: \(error). Using local-only fallback.")
            // Silent — fall back to local
            currentUser?.displayName = name
        }
    }

    func updatePlanTier(_ tier: PlanTier) async {
        guard let userId = currentUser?.id else { return }
        var update = UserProfileUpdate()
        update.plan_tier = tier.rawValue
        do {
            try await client.from("profiles").update(update).eq("id", value: userId).execute()
            print("🟢 AuthService: Successfully updated plan tier to '\(tier.rawValue)' in Supabase.")
        } catch {
            print("🔴 AuthService.updatePlanTier failed: \(error)")
            // Silent — RevenueCat is source of truth so cache locally
        }
        currentUser?.planTier = tier
    }

    func updateReminderSettings(enabled: Bool, time: Date?) async {
        guard let userId = currentUser?.id else { return }
        var update = UserProfileUpdate()
        update.reminder_enabled = enabled
        update.reminder_time = time
        do {
            try await client.from("profiles").update(update).eq("id", value: userId).execute()
            print("🟢 AuthService: Successfully updated reminder settings in Supabase.")
        } catch {
            print("🔴 AuthService.updateReminderSettings failed: \(error)")
            // ignore — best effort
        }
        currentUser?.reminderEnabled = enabled
        currentUser?.reminderTime = time
    }

    func updateStreakStats(streak: Int, totalCheckIns: Int, lastDate: Date) async {
        guard let userId = currentUser?.id else { return }
        var update = UserProfileUpdate()
        update.check_in_streak = streak
        update.total_check_ins = totalCheckIns
        update.last_check_in_date = lastDate
        do {
            try await client.from("profiles").update(update).eq("id", value: userId).execute()
            print("🟢 AuthService: Successfully updated streak/checkin stats in Supabase.")
        } catch {
            print("🔴 AuthService.updateStreakStats failed: \(error)")
            // ignore — best effort
        }
        currentUser?.checkInStreak = streak
        currentUser?.totalCheckIns = totalCheckIns
        currentUser?.lastCheckInDate = lastDate
    }

    // MARK: - Apple Helpers

    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess { continue }
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple delegate

extension AuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        DispatchQueue.main.sync {
            UIApplication.shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard
                let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = appleCredential.identityToken,
                let identityToken = String(data: identityTokenData, encoding: .utf8),
                let nonce = self.appleNonce
            else {
                if self.pendingDeleteContinuation != nil {
                    self.pendingDeleteContinuation?.resume(throwing: AppError.authFailed("Apple re-authentication failed."))
                    self.pendingDeleteContinuation = nil
                } else {
                    self.pendingAppleContinuation?.resume(throwing: AppError.authFailed("Apple Sign In failed."))
                    self.pendingAppleContinuation = nil
                }
                return
            }

            do {
                if self.pendingDeleteContinuation != nil {
                    self.pendingDeleteContinuation?.resume(returning: identityToken)
                    self.pendingDeleteContinuation = nil
                    return
                }

                let session = try await client.auth.signInWithIdToken(
                    credentials: .init(provider: .apple, idToken: identityToken, nonce: nonce)
                )
                let email = session.user.email ?? appleCredential.email ?? ""
                let displayName: String? = {
                    if let name = appleCredential.fullName {
                        let formatter = PersonNameComponentsFormatter()
                        let formatted = formatter.string(from: name)
                        return formatted.isEmpty ? nil : formatted
                    }
                    return nil
                }()
                try? await self.ensureProfileExists(userId: session.user.id.uuidString, email: email, displayName: displayName)
                await self.loadProfile(userId: session.user.id.uuidString, email: email)
                self.isAuthenticated = true
                self.authProvider = .apple
                self.pendingAppleContinuation?.resume(returning: ())
            } catch {
                if self.pendingDeleteContinuation != nil {
                    self.pendingDeleteContinuation?.resume(throwing: error)
                    self.pendingDeleteContinuation = nil
                } else {
                    self.pendingAppleContinuation?.resume(throwing: SupabaseErrorMapper.map(error))
                }
            }
            self.pendingAppleContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            self.pendingAppleContinuation?.resume(throwing: AppError.authFailed("Apple Sign In was cancelled or failed."))
            self.pendingAppleContinuation = nil
        }
    }
}
