import SwiftUI

enum EnergyCenter: String, CaseIterable, Codable, Identifiable {
    case root = "root"
    case sacral = "sacral"
    case solar = "solar"
    case heart = "heart"
    case throat = "throat"
    case thirdEye = "third_eye"
    case crown = "crown"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .root: return "Root"
        case .sacral: return "Sacral"
        case .solar: return "Solar Plexus"
        case .heart: return "Heart"
        case .throat: return "Throat"
        case .thirdEye: return "Third Eye"
        case .crown: return "Crown"
        }
    }

    var subtitle: String {
        switch self {
        case .root: return "Safety & Security"
        case .sacral: return "Creativity & Flow"
        case .solar: return "Power & Confidence"
        case .heart: return "Love & Compassion"
        case .throat: return "Expression & Truth"
        case .thirdEye: return "Insight & Intuition"
        case .crown: return "Connection & Meaning"
        }
    }

    var color: Color {
        switch self {
        case .root: return AniccaTheme.chakraRoot
        case .sacral: return AniccaTheme.chakraSacral
        case .solar: return AniccaTheme.chakraSolar
        case .heart: return AniccaTheme.chakraHeart
        case .throat: return AniccaTheme.chakraThroat
        case .thirdEye: return AniccaTheme.chakraThirdEye
        case .crown: return AniccaTheme.chakraCrown
        }
    }

    var sfSymbol: String {
        switch self {
        case .root: return "shield.fill"
        case .sacral: return "drop.fill"
        case .solar: return "sun.max.fill"
        case .heart: return "heart.fill"
        case .throat: return "waveform"
        case .thirdEye: return "eye.fill"
        case .crown: return "sparkles"
        }
    }

    var number: Int {
        switch self {
        case .root: return 1
        case .sacral: return 2
        case .solar: return 3
        case .heart: return 4
        case .throat: return 5
        case .thirdEye: return 6
        case .crown: return 7
        }
    }

    var description: String {
        switch self {
        case .root:
            return "Your sense of safety, stability, and being at home in your body."
        case .sacral:
            return "Your capacity for creativity, play, and emotional flow."
        case .solar:
            return "Your confidence, agency, and ability to take action."
        case .heart:
            return "Your openness to love, both received and given."
        case .throat:
            return "Your ability to speak truthfully and express yourself."
        case .thirdEye:
            return "Your intuition, perception, and inner clarity."
        case .crown:
            return "Your connection to meaning, purpose, and wholeness."
        }
    }
 
    var fallbackSuggestions: [String] {
        switch self {
        case .root:
            return [
                "Stand barefoot on the earth or floor for 2 minutes, feeling your weight pull down.",
                "Take 5 slow, deep breaths, focusing entirely on the sensation of your feet on the ground.",
                "Wrap yourself in a heavy blanket and repeat quietly: 'I am safe and supported in this moment.'"
            ]
        case .sacral:
            return [
                "Spend 3 minutes free-writing or doodling without any plan or goal.",
                "Drink a warm glass of water slowly, paying full attention to the sensation of the liquid.",
                "Stretch your hips gently while breathing slowly into your lower abdomen."
            ]
        case .solar:
            return [
                "Stand in a strong, open posture (shoulders back, hands on hips) for 1 minute.",
                "Name three small things you successfully accomplished or decided today.",
                "Take a brisk, fast-paced walk around the room to shift your physical energy."
            ]
        case .heart:
            return [
                "Place both hands over your chest, breathing softly under their warmth for 1 minute.",
                "Send a silent, genuine wish of wellness or peace to someone you care about.",
                "Write down one thing you truly appreciate about yourself right now."
            ]
        case .throat:
            return [
                "Hum a soft, steady tone for 30 seconds to feel the vibration in your throat.",
                "Write down exactly what you are feeling in one unfiltered, raw sentence.",
                "Sip a cup of warm tea and practice letting your jaw completely relax."
            ]
        case .thirdEye:
            return [
                "Close your eyes and breathe, visualizing a calm indigo light between your eyebrows.",
                "Look away from all screens and let your eyes rest on a single object in the room.",
                "Sit in complete silence for 2 minutes, simply observing thoughts passing like clouds."
            ]
        case .crown:
            return [
                "Look up at the sky or out a window, connecting with the vast space around you.",
                "Sit quietly and recall a moment you felt deeply connected to nature or a bigger purpose.",
                "Close your eyes and repeat: 'I am part of a larger, beautiful whole.'"
            ]
        }
    }
}

enum CenterStatus: String, Codable {
    case noData
    case underactive
    case balanced
    case overactive

    var displayName: String {
        switch self {
        case .noData: return "No data"
        case .underactive: return "Underactive"
        case .balanced: return "Balanced"
        case .overactive: return "Overactive"
        }
    }

    var color: Color {
        switch self {
        case .noData: return AniccaTheme.textMuted
        case .underactive: return AniccaTheme.warning
        case .balanced: return AniccaTheme.success
        case .overactive: return AniccaTheme.brandSecondary
        }
    }
}
