import Foundation

enum EmotionValence: String, Codable, Hashable {
    case positive
    case neutral
    case negative
}

struct Emotion: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let center: EnergyCenter
    let valence: EmotionValence
    let sfSymbol: String
    let description: String
    let synonyms: [String]

    init(name: String, center: EnergyCenter, valence: EmotionValence, sfSymbol: String, description: String, synonyms: [String] = []) {
        // Deterministic ID per (center,name) so persistence is stable across launches.
        let seed = "\(center.rawValue)::\(name)"
        let hash = seed.hashValue
        let bytes = withUnsafeBytes(of: hash) { Data($0) } + withUnsafeBytes(of: hash.byteSwapped) { Data($0) }
        var uuidBytes = [UInt8](bytes.prefix(16))
        while uuidBytes.count < 16 { uuidBytes.append(0) }
        self.id = UUID(uuid: (
            uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
            uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
            uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
            uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
        ))
        self.name = name
        self.center = center
        self.valence = valence
        self.sfSymbol = sfSymbol
        self.description = description
        self.synonyms = synonyms
    }
}
