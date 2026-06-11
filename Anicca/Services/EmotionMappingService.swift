import Foundation

// MARK: - Mapped Emotion

struct MappedEmotion: Identifiable {
    let id = UUID()
    let emotion: Emotion
    var intensity: Int          // 1–5, pre-seeded by Gemini or default 3
    var isTouched: Bool = true  // AI-seeded means already "touched" → Save unlocks immediately
}

// MARK: - Emotion Mapping Service

actor EmotionMappingService {
    static let shared = EmotionMappingService()

    private let apiKey: String
    private let endpoint = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent")!
    private let session: URLSession

    private init() {
        self.apiKey = AppConfig.geminiAPIKey
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 45
        self.session = URLSession(configuration: config)
    }

    // MARK: - Free Text → Emotions

    func mapFreeText(_ text: String) async throws -> [MappedEmotion] {
        guard !apiKey.isEmpty else { throw EmotionMappingError.missingKey }

        let systemPrompt = """
        You are an emotion mapping assistant for a chakra-based wellness app called Anicca.

        The 7 chakras and their associated emotion domains are:
        - Root (Safety & Security): Anxious, Insecure, Disconnected, Restless, Cautious, Still, Settling, Present, Grounded, Secure, Stable, Safe, Supported, Rooted
        - Sacral (Creativity & Flow): Stuck, Numb, Guilty, Uninspired, Stirring, Yearning, Yielding, Fluid, Playful, Creative, Passionate, Flowing, Joyful, Sensual
        - Solar Plexus (Power & Confidence): Powerless, Inadequate, Frustrated, Overwhelmed, Hesitant, Ambitious, Driven, Determined, Confident, Empowered, Capable, Bold, Radiant, Assured
        - Heart (Love & Compassion): Lonely, Closed, Hurt, Grieving, Guarded, Receptive, Tender, Vulnerable, Loving, Compassionate, Grateful, Accepted, Forgiving, Peaceful
        - Throat (Expression & Truth): Misunderstood, Silenced, Constricted, Withdrawn, Reflective, Listening, Processing, Honest, Expressive, Authentic, Heard, Understood, Clear, Articulate
        - Third Eye (Intuition & Clarity): Confused, Scattered, Doubtful, Foggy, Contemplative, Observant, Wondering, Curious, Intuitive, Aware, Perceptive, Insightful, Clear-minded, Focused
        - Crown (Connection & Meaning): Meaningless, Disconnected, Cynical, Hollow, Searching, Surrendering, Open, Reflective, Connected, Whole, Purposeful, Transcendent, Blissful, Unified

        Given the user's free text input, return a JSON object mapping their emotional state to the most relevant emotions from the above list. Return 1–5 emotions maximum. For each, provide your best estimate of intensity (1–5). Do not include emotions not in the list above. If the input is ambiguous, choose the closest match.

        Return ONLY valid JSON in this exact format, no preamble, no markdown:
        {
          "emotions": [
            {
              "name": "Anxious",
              "chakra": "Root",
              "intensity": 3
            }
          ]
        }
        """

        let userPrompt = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawJSON = try await callGemini(systemPrompt: systemPrompt, userText: userPrompt)
        return try parseMappedEmotions(from: rawJSON)
    }

    // MARK: - Semantic Search

    func searchEmotions(query: String) async throws -> [Emotion] {
        guard !apiKey.isEmpty else { throw EmotionMappingError.missingKey }
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        let allNames = EmotionLibrary.all.map { $0.name }.joined(separator: " | ")

        let systemPrompt = """
        You are a semantic search assistant for a wellness app. Return only the JSON array requested, with no preamble or markdown.
        """

        let userPrompt = """
        The user typed: "\(query)"

        From this emotion list, return the 1–5 most semantically similar emotions to what the user typed. Consider synonyms, related concepts, and colloquial expressions. Be inclusive — if "angry" matches "Frustrated", include it.

        Emotion list: \(allNames)

        Return ONLY a JSON array of matching emotion names in order of relevance, exactly as they appear in the list:
        ["EmotionName1", "EmotionName2"]
        """

        let rawJSON = try await callGemini(systemPrompt: systemPrompt, userText: userPrompt)
        return try parseSearchResults(from: rawJSON)
    }

    // MARK: - Gemini HTTP Call

    private func callGemini(systemPrompt: String, userText: String) async throws -> String {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else { throw EmotionMappingError.networkError }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                ["role": "user", "parts": [["text": userText]]]
            ],
            "generationConfig": [
                "temperature": 0.2,
                "topP": 0.8,
                "maxOutputTokens": 400
            ],
            "safetySettings": [
                ["category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"],
                ["category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw EmotionMappingError.networkError
        }

        guard let http = response as? HTTPURLResponse else {
            throw EmotionMappingError.invalidResponse
        }

        if !(200..<300).contains(http.statusCode) {
            if let errorBody = String(data: data, encoding: .utf8) {
                print("🔴 Gemini API Error Response (HTTP \(http.statusCode)): \(errorBody)")
            } else {
                print("🔴 Gemini API Error Response (HTTP \(http.statusCode)) with unreadable body")
            }
            throw EmotionMappingError.invalidResponse
        }

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = json["candidates"] as? [[String: Any]],
            let first = candidates.first,
            let content = first["content"] as? [String: Any],
            let parts = content["parts"] as? [[String: Any]],
            let text = parts.first?["text"] as? String
        else {
            throw EmotionMappingError.parseError
        }
        return text
    }

    // MARK: - Parsing

    private func parseMappedEmotions(from rawJSON: String) throws -> [MappedEmotion] {
        let cleaned = extractJSON(rawJSON)
        guard let data = cleaned.data(using: .utf8) else { throw EmotionMappingError.parseError }

        struct Wrapper: Decodable {
            let emotions: [RawMapped]
        }
        struct RawMapped: Decodable {
            let name: String
            let chakra: String
            let intensity: Int
        }

        let wrapper: Wrapper
        do {
            wrapper = try JSONDecoder().decode(Wrapper.self, from: data)
        } catch {
            print("🔴 parseMappedEmotions failed to decode JSON. Raw response from Gemini: '\(rawJSON)' | Cleaned: '\(cleaned)' | Error: \(error)")
            throw error
        }

        let chakraMap: [String: EnergyCenter] = [
            "Root": .root, "Sacral": .sacral, "Solar Plexus": .solar,
            "Heart": .heart, "Throat": .throat, "Third Eye": .thirdEye, "Crown": .crown
        ]

        var results: [MappedEmotion] = []
        var seenIds = Set<UUID>()
        for raw in wrapper.emotions.prefix(5) {
            guard let center = chakraMap[raw.chakra] else { continue }
            // Find exact match first, then case-insensitive fallback
            let emotion = EmotionLibrary.byCenter[center]?.first {
                $0.name.caseInsensitiveCompare(raw.name) == .orderedSame
            } ?? EmotionLibrary.all.first {
                $0.name.caseInsensitiveCompare(raw.name) == .orderedSame
            }
            guard let e = emotion, !seenIds.contains(e.id) else { continue }
            seenIds.insert(e.id)
            let clamped = max(1, min(5, raw.intensity))
            results.append(MappedEmotion(emotion: e, intensity: clamped, isTouched: true))
        }
        return results
    }

    private func parseSearchResults(from rawJSON: String) throws -> [Emotion] {
        let cleaned = extractJSONArray(rawJSON)
        guard let data = cleaned.data(using: .utf8) else { throw EmotionMappingError.parseError }
        let names = try JSONDecoder().decode([String].self, from: data)
        return names.compactMap { name in
            EmotionLibrary.all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
        }
    }

    private func extractJSON(_ text: String) -> String {
        var out = text.trimmingCharacters(in: .whitespacesAndNewlines)
        out = out.replacingOccurrences(of: "```json", with: "")
        out = out.replacingOccurrences(of: "```", with: "")
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = out.firstIndex(of: "{"), let last = out.lastIndex(of: "}") {
            return String(out[first...last])
        }
        return out
    }

    private func extractJSONArray(_ text: String) -> String {
        var out = text.trimmingCharacters(in: .whitespacesAndNewlines)
        out = out.replacingOccurrences(of: "```json", with: "")
        out = out.replacingOccurrences(of: "```", with: "")
        out = out.trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = out.firstIndex(of: "["), let last = out.lastIndex(of: "]") {
            return String(out[first...last])
        }
        return out
    }
}

// MARK: - Errors

enum EmotionMappingError: Error {
    case missingKey
    case networkError
    case invalidResponse
    case parseError
}
