import Foundation
import Supabase

enum AIServiceError: Error {
    case networkError
    case rateLimited
    case invalidResponse
    case parseError
    case missingKey
}

actor AIService {
    static let shared = AIService()

    private let apiKey: String
    private let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent")!
    private let session: URLSession
    private let client: SupabaseClient

    private init() {
        self.apiKey = AppConfig.geminiAPIKey
        self.client = SupabaseConfig.shared.client
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 45
        self.session = URLSession(configuration: config)
    }

    // MARK: - Weekly Insight

    func generateWeeklyInsight(
        userId: String,
        entries: [EmotionEntry],
        dominantCenter: EnergyCenter
    ) async throws -> AIInsight {
        let weekStart = Date().startOfWeek
        if let cached = try? await fetchCached(userId: userId, weekStart: weekStart) {
            return cached
        }
 
        do {
            guard !apiKey.isEmpty else { throw AIServiceError.missingKey }
 
            let insightsService = InsightsService()
            let last14 = insightsService.entriesInLast(days: 14, from: entries.compactMap { $0.checkIn }.uniqued())
            let top = insightsService.topEmotions(in: entries, limit: 5)
            let valence = insightsService.valenceTrend(in: entries)
            var perCenter: [(EnergyCenter, Int)] = []
            for center in EnergyCenter.allCases {
                perCenter.append((center, insightsService.entryCount(per: center, in: entries)))
            }
 
            let userPrompt = """
            Here is the user's emotional check-in data over the last 14 days.

            Counts per energy center:
            \(perCenter.map { "  \($0.0.displayName) (\($0.0.subtitle)): \($0.1)" }.joined(separator: "\n"))

            Top 5 most frequent emotions:
            \(top.map { "  \($0.name) — \($0.count)x, avg intensity \(String(format: "%.1f", $0.avgIntensity)), center: \($0.center.displayName)" }.joined(separator: "\n"))

            Dominant center: \(dominantCenter.displayName) — \(dominantCenter.subtitle)
            Valence trend: \(valence.positive) positive, \(valence.neutral) neutral, \(valence.negative) negative.
            Total entries considered: \(last14.count)

            Return STRICT JSON with this exact shape and nothing else:
            {
              "insight": "3-4 sentence personalized reflection in second person",
              "dominant_center": "\(dominantCenter.rawValue)",
              "suggested_practices": ["practice 1", "practice 2", "practice 3"]
            }
            """
 
            let insight = try await callGemini(systemInstruction: Self.systemInstruction, userText: userPrompt)
            let parsed = try parseInsight(rawText: insight, weekStart: weekStart)
            await cache(parsed, userId: userId, weekStart: weekStart)
            return parsed
        } catch {
            // Fallback to high-quality handcrafted weekly insights if the Gemini API key is invalid/unavailable
            return generateHandcraftedWeeklyInsight(dominantCenter: dominantCenter, entries: entries, weekStart: weekStart)
        }
    }
 
    private func generateHandcraftedWeeklyInsight(
        dominantCenter: EnergyCenter,
        entries: [EmotionEntry],
        weekStart: Date
    ) -> AIInsight {
        let insightsService = InsightsService()
        let top = insightsService.topEmotions(in: entries, limit: 3)
        
        let topEmotionsStr = top.isEmpty ? "your feelings" : top.map { $0.name.lowercased() }.joined(separator: ", ")
        
        let insightText: String
        let practices: [String]
        
        switch dominantCenter {
        case .root:
            insightText = "This week, your focus settled heavily in your Root center, reflecting themes of grounding, safety, and stability. With \(topEmotionsStr) being prominent, you may have been navigating feelings of uncertainty or seeking solid ground. Remember that safety starts from within; finding comfort in small daily routines can help you feel more secure."
            practices = [
                "Establish a simple morning grounding ritual, like sitting quietly with your feet flat on the floor.",
                "Take a slow 5-minute walk outside, focusing entirely on the physical connection of your feet to the earth.",
                "Spend a few minutes organizing one small area of your living space to create external stability."
            ]
        case .sacral:
            insightText = "Your emotional activity this week centered in your Sacral space, indicating a focus on flow, creativity, and personal desires. Prominent feelings of \(topEmotionsStr) show you are deeply in touch with your emotional waters. Giving yourself permission to feel without judgment will unlock your creative and playful energy."
            practices = [
                "Engage in 5 minutes of unstructured doodling, writing, or movement with no goal.",
                "Sip a warm drink mindfully, fully noticing the warmth and sensation in your body.",
                "Dedicate 10 minutes to a creative hobby or play purely for the joy of it."
            ]
        case .solar:
            insightText = "This week, your solar plexus took center stage, highlighting themes of power, confidence, and personal agency. Feeling \(topEmotionsStr) suggests you are working through your relationship with control, action, and self-worth. You have the power to direct your life—focus on building your inner fire steadily and mindfully."
            practices = [
                "Stand in a strong, open posture (shoulders back, chest open) for 1 minute before starting your day.",
                "Write down three small decisions you made today that align with your true desires.",
                "Do a quick, high-energy stretch or brisk walk to physically activate your personal power."
            ]
        case .heart:
            insightText = "Your heart center was the focal point of your week, bringing up themes of love, compassion, and emotional openness. Navigating \(topEmotionsStr) shows a strong connection to relationship boundaries and self-acceptance. Softening your edges and practicing self-compassion will help keep this center balanced."
            practices = [
                "Place both hands over your heart for 2 minutes, breathing softly into the warmth of your touch.",
                "Write down one thing you truly appreciate about yourself or someone close to you.",
                "Practice a simple loving-kindness meditation, wishing peace and ease to yourself and others."
            ]
        case .throat:
            insightText = "This week settled heavily in your Throat center, reflecting themes of truth, self-expression, and communication. With \(topEmotionsStr) leading your entries, you might have felt a push to speak up or had difficulty finding the right words. Authentic expression isn't just about speaking—it's also about listening deeply to your inner voice."
            practices = [
                "Write a raw, unedited note on how you truly feel, then delete or discard it safely.",
                "Hum a gentle, steady tone for 1 minute to feel the vibration physically in your throat.",
                "Practice active listening in your next conversation, focusing completely on hearing rather than replying."
            ]
        case .thirdEye:
            insightText = "Your focus this week was in your Third Eye center, highlighting your intuition, perception, and inner clarity. Navigating \(topEmotionsStr) indicates you are actively reflecting on your life patterns and seeking deeper truth. Trust your gut feelings; your inner guidance is incredibly strong when you quiet the noise."
            practices = [
                "Close your eyes and breathe, visualizing a calm indigo light resting between your eyebrows.",
                "Take a 5-minute screen break and let your eyes rest on the farthest horizon you can see.",
                "Write down any repetitive thoughts or intuitive nudges you've had recently."
            ]
        case .crown:
            insightText = "This week focused heavily on your Crown center, bringing forward themes of connection, meaning, and your place in the larger picture. Your experience of \(topEmotionsStr) suggests a period of seeking higher purpose or navigating existential space. Remember that you are connected to the flow of life; trust that you belong exactly where you are."
            practices = [
                "Spend 5 minutes looking at the sky or trees, connecting with the vast space around you.",
                "Sit in quiet gratitude for a moment you felt deeply at peace or part of a beautiful whole.",
                "Repeat a simple reminder of wholeness: 'I am part of the universe, and I am supported.'"
            ]
        }
        
        return AIInsight(
            insight: insightText,
            dominantCenter: dominantCenter,
            suggestedPractices: practices,
            weekStart: weekStart
        )
    }

    // MARK: - Center Suggestion

    func generateCenterSuggestion(
        for center: EnergyCenter,
        recentEntries: [EmotionEntry]
    ) async throws -> [String] {
        guard !apiKey.isEmpty else { throw AIServiceError.missingKey }

        let recent = recentEntries
            .filter { $0.energyCenter == center }
            .prefix(5)

        let userPrompt = """
        The user wants supportive practices for their \(center.displayName) center (\(center.subtitle)).

        Their recent \(center.displayName) emotions:
        \(recent.map { "  \($0.emotionName) (intensity \($0.intensity))" }.joined(separator: "\n"))

        Return STRICT JSON with this exact shape and nothing else:
        {
          "suggested_practices": ["practice 1", "practice 2", "practice 3"]
        }

        Each practice should be one sentence, embodied, concrete, and doable in 5 minutes.
        """

        let text = try await callGemini(systemInstruction: Self.systemInstruction, userText: userPrompt)
        guard let data = extractJSON(text).data(using: .utf8) else {
            throw AIServiceError.parseError
        }
        struct Wrapper: Decodable { let suggested_practices: [String] }
        do {
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
            return wrapper.suggested_practices
        } catch {
            throw AIServiceError.parseError
        }
    }

    // MARK: - Gemini Call

    private func callGemini(systemInstruction: String, userText: String) async throws -> String {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else { throw AIServiceError.networkError }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemInstruction]]
            ],
            "contents": [
                ["role": "user", "parts": [["text": userText]]]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topP": 0.9,
                "maxOutputTokens": 600,
                "responseMimeType": "application/json"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AIServiceError.networkError
        }

        guard let http = response as? HTTPURLResponse else { throw AIServiceError.networkError }
        if http.statusCode == 429 { throw AIServiceError.rateLimited }
        guard (200..<300).contains(http.statusCode) else { throw AIServiceError.invalidResponse }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let first = candidates.first,
            let content = first["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw AIServiceError.invalidResponse
        }
        return text
    }

    // MARK: - Parsing

    private func parseInsight(rawText: String, weekStart: Date) throws -> AIInsight {
        let cleaned = extractJSON(rawText)
        guard let data = cleaned.data(using: .utf8) else { throw AIServiceError.parseError }

        struct Wrapper: Decodable {
            let insight: String
            let dominant_center: String?
            let suggested_practices: [String]?
        }

        do {
            let wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
            let center = wrapper.dominant_center.flatMap { EnergyCenter(rawValue: $0) }
            return AIInsight(
                insight: wrapper.insight,
                dominantCenter: center,
                suggestedPractices: wrapper.suggested_practices ?? [],
                weekStart: weekStart
            )
        } catch {
            throw AIServiceError.parseError
        }
    }

    private func extractJSON(_ text: String) -> String {
        // Strip code fences if Gemini adds them.
        var out = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if out.hasPrefix("```") {
            out = out.replacingOccurrences(of: "```json", with: "")
            out = out.replacingOccurrences(of: "```", with: "")
            out = out.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let firstBrace = out.firstIndex(of: "{"), let lastBrace = out.lastIndex(of: "}") {
            return String(out[firstBrace...lastBrace])
        }
        return out
    }

    // MARK: - Cache

    private func fetchCached(userId: String, weekStart: Date) async throws -> AIInsight? {
        guard let userUUID = UUID(uuidString: userId) else { return nil }
        let dateString = Self.dateKey(weekStart)
        do {
            let row: AIInsightDTO = try await client
                .from("ai_insights")
                .select()
                .eq("user_id", value: userUUID)
                .eq("week_start", value: dateString)
                .single()
                .execute()
                .value
            return AIInsight(
                id: row.id,
                insight: row.insight_text,
                dominantCenter: row.dominant_center.flatMap { EnergyCenter(rawValue: $0) },
                suggestedPractices: row.suggested_practices,
                weekStart: weekStart
            )
        } catch {
            return nil
        }
    }

    private func cache(_ insight: AIInsight, userId: String, weekStart: Date) async {
        guard let userUUID = UUID(uuidString: userId) else { return }
        let insert = AIInsightInsert(
            user_id: userUUID,
            week_start: Self.dateKey(weekStart),
            insight_text: insight.insight,
            dominant_center: insight.dominantCenter?.rawValue,
            suggested_practices: insight.suggestedPractices
        )
        _ = try? await client
            .from("ai_insights")
            .upsert(insert, onConflict: "user_id,week_start")
            .execute()
    }

    private static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }

    // MARK: - System Instruction

    private static let systemInstruction = """
    You are a compassionate, grounded wellness guide for an app called Anicca. The user tracks their emotions through the lens of chakra energy centers. Your tone is warm, honest, secular, and non-coercive. Never use toxic positivity. Never diagnose. Speak directly to the user in second person. Always return strict JSON exactly matching the shape requested — no preamble, no markdown.
    """
}

private extension Array where Element == CheckIn {
    func uniqued() -> [CheckIn] {
        var seen = Set<UUID>()
        return filter { seen.insert($0.id).inserted }
    }
}
