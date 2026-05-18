import Foundation
import SwiftData

@Model
final class CheckIn {
    @Attribute(.unique) var id: UUID
    var userId: String
    var createdAt: Date
    var note: String?
    @Relationship(deleteRule: .cascade, inverse: \EmotionEntry.checkIn)
    var entries: [EmotionEntry] = []
    var syncedToSupabase: Bool

    init(
        id: UUID = UUID(),
        userId: String,
        createdAt: Date = Date(),
        note: String? = nil,
        entries: [EmotionEntry] = [],
        syncedToSupabase: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.createdAt = createdAt
        self.note = note
        self.entries = entries
        self.syncedToSupabase = syncedToSupabase
    }
 
    var sortedEntries: [EmotionEntry] {
        entries.sorted { e1, e2 in
            if e1.energyCenter.number != e2.energyCenter.number {
                return e1.energyCenter.number < e2.energyCenter.number
            }
            return e1.emotionName < e2.emotionName
        }
    }
}

@Model
final class EmotionEntry {
    @Attribute(.unique) var id: UUID
    var emotionName: String
    var energyCenterRaw: String
    var intensity: Int
    var checkInId: UUID
    var checkIn: CheckIn?

    init(
        id: UUID = UUID(),
        emotionName: String,
        energyCenter: EnergyCenter,
        intensity: Int,
        checkInId: UUID,
        checkIn: CheckIn? = nil
    ) {
        self.id = id
        self.emotionName = emotionName
        self.energyCenterRaw = energyCenter.rawValue
        self.intensity = intensity
        self.checkInId = checkInId
        self.checkIn = checkIn
    }

    var energyCenter: EnergyCenter {
        EnergyCenter(rawValue: energyCenterRaw) ?? .heart
    }
}

// MARK: - Codable wire formats for Supabase

struct CheckInDTO: Codable {
    let id: UUID
    let user_id: UUID
    let note: String?
    let created_at: Date
}

struct CheckInInsert: Codable {
    let id: UUID
    let user_id: UUID
    let note: String?
    let created_at: Date
}

struct EmotionEntryDTO: Codable {
    let id: UUID
    let check_in_id: UUID
    let user_id: UUID
    let emotion_name: String
    let energy_center: String
    let intensity: Int
    let created_at: Date
}

struct EmotionEntryInsert: Codable {
    let id: UUID
    let check_in_id: UUID
    let user_id: UUID
    let emotion_name: String
    let energy_center: String
    let intensity: Int
}
