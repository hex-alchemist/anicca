import SwiftUI

struct AniccaCardModifier: ViewModifier {
    var padding: CGFloat = AniccaTheme.Spacing.s20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                            .fill(Color.white.opacity(0.6))
                    }
            }
            .shadow(
                color: AniccaTheme.cardShadowColor,
                radius: AniccaTheme.cardShadowRadius,
                x: 0,
                y: AniccaTheme.cardShadowY
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var disabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AniccaTheme.Spacing.s16)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                    .fill(disabled ? AniccaTheme.textMuted : AniccaTheme.brandPrimary)
            }
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(AniccaTheme.brandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AniccaTheme.Spacing.s16)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                    .stroke(AniccaTheme.brandSecondary, lineWidth: 1.5)
                    .background {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                            .fill(Color.white.opacity(0.4))
                    }
            }
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AniccaTheme.textSecondary)
            .padding(.vertical, AniccaTheme.Spacing.s12)
            .padding(.horizontal, AniccaTheme.Spacing.s16)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension View {
    func aniccaCard(padding: CGFloat = AniccaTheme.Spacing.s20) -> some View {
        modifier(AniccaCardModifier(padding: padding))
    }
}

// MARK: - Mesh Gradient Background

struct MeshGradientBackground: View {
    @State private var animate: Bool = false

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                TimelineView(.animation(minimumInterval: 0.05)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let offset = Float(sin(t * 0.3) * 0.08)
                    let offset2 = Float(cos(t * 0.25) * 0.08)

                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: [
                            SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                            SIMD2<Float>(0.0, 0.5 + offset), SIMD2<Float>(0.5 + offset2, 0.5), SIMD2<Float>(1.0, 0.5 - offset),
                            SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
                        ],
                        colors: [
                            AniccaTheme.background, AniccaTheme.brandAccent.opacity(0.35), Color(hex: "#FFE5D9"),
                            AniccaTheme.brandAccent.opacity(0.25), AniccaTheme.background, Color(hex: "#D4F1E0").opacity(0.6),
                            Color(hex: "#FFE5D9").opacity(0.7), AniccaTheme.brandSecondary.opacity(0.3), AniccaTheme.background
                        ]
                    )
                }
                .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        AniccaTheme.background,
                        AniccaTheme.brandAccent.opacity(0.25),
                        Color(hex: "#FFE5D9").opacity(0.5),
                        AniccaTheme.background
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }
}
