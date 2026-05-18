import Foundation

enum AppConfig {
    static let supabaseURL: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !raw.isEmpty,
              let url = URL(string: raw.replacingOccurrences(of: "\\", with: ""))
        else {
            assertionFailure("SUPABASE_URL missing from Info.plist — check Secrets.xcconfig")
            return URL(string: "https://placeholder.supabase.co")!
        }
        return url
    }()

    static let supabaseAnonKey: String = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !raw.isEmpty
        else {
            assertionFailure("SUPABASE_ANON_KEY missing from Info.plist — check Secrets.xcconfig")
            return ""
        }
        return raw
    }()

    static let geminiAPIKey: String = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !raw.isEmpty
        else {
            return ""
        }
        return raw
    }()

    static let revenueCatAPIKey: String = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
              !raw.isEmpty
        else {
            return ""
        }
        return raw
    }()

    static let googleClientID: String = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String,
              !raw.isEmpty
        else {
            return ""
        }
        return raw
    }()

    // MARK: - Constants
    static let freeMonthlyCheckInLimit = 30
    static let freeMonthlyWarningThreshold = 25
    static let onboardingCompleteKey = "anicca_onboarding_complete"
    static let lastReviewVersionKey = "anicca_last_review_version"
    static let reminderNotificationID = "anicca.daily.reminder"

    // MARK: - URLs
    static let privacyPolicyURL = URL(string: "https://anicca.lovable.app/privacy")!
    static let termsOfUseURL = URL(string: "https://anicca.lovable.app/terms")!
    static let yggdrasilURL = URL(string: "https://yggdrasil-journal.lovable.app/")!

    // MARK: - Build Info
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
