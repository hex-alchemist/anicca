import Foundation
import SwiftData

enum PlanTier: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case bundle = "bundle"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro ✦"
        case .bundle: return "Bundle ✦✦"
        }
    }

    var isPaid: Bool {
        self == .pro || self == .bundle
    }
}

@Model
final class UserProfile {
    @Attribute(.unique) var id: String
    var email: String
    var displayName: String?
    var planTierRaw: String
    var checkInStreak: Int
    var lastCheckInDate: Date?
    var totalCheckIns: Int
    var reminderEnabled: Bool
    var reminderTime: Date?
    var createdAt: Date

    init(
        id: String,
        email: String,
        displayName: String? = nil,
        planTier: PlanTier = .free,
        checkInStreak: Int = 0,
        lastCheckInDate: Date? = nil,
        totalCheckIns: Int = 0,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.planTierRaw = planTier.rawValue
        self.checkInStreak = checkInStreak
        self.lastCheckInDate = lastCheckInDate
        self.totalCheckIns = totalCheckIns
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
        self.createdAt = createdAt
    }

    var planTier: PlanTier {
        get {
            if UserDefaults.standard.bool(forKey: "developer_override_pro") {
                return .pro
            }
            return PlanTier(rawValue: planTierRaw) ?? .free
        }
        set { planTierRaw = newValue.rawValue }
    }

    var initials: String {
        let source = displayName?.isEmpty == false ? displayName! : email
        let parts = source.split(separator: " ")
        if parts.count >= 2,
           let first = parts[0].first,
           let second = parts[1].first {
            return "\(first)\(second)".uppercased()
        }
        return String(source.prefix(2)).uppercased()
    }
}

// MARK: - Codable DTO for Supabase

struct UserProfileDTO: Codable {
    let id: String
    let email: String
    let display_name: String?
    let plan_tier: String
    let check_in_streak: Int
    let last_check_in_date: Date?
    let total_check_ins: Int
    let reminder_enabled: Bool
    let reminder_time: Date?
    let yggdrasil_user_id: String?
    let created_at: Date
}

struct UserProfileInsert: Codable {
    let id: String
    let email: String
    let display_name: String?
    let plan_tier: String
}

struct UserProfileUpdate: Codable {
    var display_name: String?
    var plan_tier: String?
    var check_in_streak: Int?
    var last_check_in_date: Date?
    var total_check_ins: Int?
    var reminder_enabled: Bool?
    var reminder_time: Date?
}
