import SwiftUI

enum AniccaTheme {
    // MARK: - Backgrounds
    static let background = Color(hex: "#F5F0FA")
    static let cardBackground = Color(hex: "#FFFFFF").opacity(0.85)
    static let surfaceElevated = Color(hex: "#EDE8F5")

    // MARK: - Brand
    static let brandPrimary = Color(hex: "#7C5CBF")
    static let brandSecondary = Color(hex: "#A78BDA")
    static let brandAccent = Color(hex: "#C4A8FF")

    // MARK: - Text
    static let textPrimary = Color(hex: "#1A1A2E")
    static let textSecondary = Color(hex: "#6B6B8A")
    static let textMuted = Color(hex: "#A0A0B8")

    // MARK: - Chakra Colors
    static let chakraRoot = Color(hex: "#C0392B")
    static let chakraSacral = Color(hex: "#E67E22")
    static let chakraSolar = Color(hex: "#F1C40F")
    static let chakraHeart = Color(hex: "#27AE60")
    static let chakraThroat = Color(hex: "#2980B9")
    static let chakraThirdEye = Color(hex: "#3F51B5")
    static let chakraCrown = Color(hex: "#8E44AD")

    // MARK: - Semantic
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9F0A")
    static let error = Color(hex: "#FF3B30")

    // MARK: - Spacing
    enum Spacing {
        static let s4: CGFloat = 4
        static let s8: CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s20: CGFloat = 20
        static let s24: CGFloat = 24
        static let s32: CGFloat = 32
    }

    // MARK: - Radius
    enum Radius {
        static let card: CGFloat = 20
        static let button: CGFloat = 14
        static let pill: CGFloat = 100
    }

    // MARK: - Shadow
    static let cardShadowColor = Color.black.opacity(0.06)
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowY: CGFloat = 4

    // MARK: - Animation
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.7)
}

// MARK: - Typography

enum AniccaTextStyle {
    case largeTitle, title, headline, body, subheadline, caption
}

struct AniccaTextModifier: ViewModifier {
    let style: AniccaTextStyle

    func body(content: Content) -> some View {
        switch style {
        case .largeTitle:
            content
                .font(.system(size: 34, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(AniccaTheme.textPrimary)
        case .title:
            content
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AniccaTheme.textPrimary)
        case .headline:
            content
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AniccaTheme.textPrimary)
        case .body:
            content
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(AniccaTheme.textPrimary)
        case .subheadline:
            content
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AniccaTheme.textSecondary)
        case .caption:
            content
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(AniccaTheme.textSecondary)
        }
    }
}

extension View {
    func anicca(_ style: AniccaTextStyle) -> some View {
        modifier(AniccaTextModifier(style: style))
    }
}
