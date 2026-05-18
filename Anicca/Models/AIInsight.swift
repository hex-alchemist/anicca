import Foundation

struct AIInsight: Codable, Identifiable {
    let id: UUID
    let insight: String
    let dominantCenter: EnergyCenter?
    let suggestedPractices: [String]
    let weekStart: Date

    enum CodingKeys: String, CodingKey {
        case id
        case insight
        case dominantCenter = "dominant_center"
        case suggestedPractices = "suggested_practices"
        case weekStart = "week_start"
    }

    init(
        id: UUID = UUID(),
        insight: String,
        dominantCenter: EnergyCenter?,
        suggestedPractices: [String],
        weekStart: Date
    ) {
        self.id = id
        self.insight = insight
        self.dominantCenter = dominantCenter
        self.suggestedPractices = suggestedPractices
        self.weekStart = weekStart
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.insight = try container.decode(String.self, forKey: .insight)
        if let raw = try container.decodeIfPresent(String.self, forKey: .dominantCenter) {
            self.dominantCenter = EnergyCenter(rawValue: raw)
        } else {
            self.dominantCenter = nil
        }
        self.suggestedPractices = try container.decodeIfPresent([String].self, forKey: .suggestedPractices) ?? []
        self.weekStart = try container.decodeIfPresent(Date.self, forKey: .weekStart) ?? Date().startOfWeek
    }
}

struct AIInsightDTO: Codable {
    let id: UUID
    let user_id: UUID
    let week_start: String       // date as YYYY-MM-DD
    let insight_text: String
    let dominant_center: String?
    let suggested_practices: [String]
    let created_at: Date
}

struct AIInsightInsert: Codable {
    let user_id: UUID
    let week_start: String
    let insight_text: String
    let dominant_center: String?
    let suggested_practices: [String]
}
