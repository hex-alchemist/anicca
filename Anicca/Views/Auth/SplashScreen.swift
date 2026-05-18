import SwiftUI

struct SplashScreen: View {
    @State private var fadeIn: Bool = false
    let onFinished: () -> Void

    var body: some View {
        ZStack {
            MeshGradientBackground()
            VStack(spacing: AniccaTheme.Spacing.s16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(AniccaTheme.brandPrimary)
                    .opacity(fadeIn ? 1 : 0)
                    .scaleEffect(fadeIn ? 1 : 0.85)
                Text(Strings.App.name)
                    .anicca(.largeTitle)
                    .opacity(fadeIn ? 1 : 0)
                Text(Strings.App.tagline)
                    .anicca(.caption)
                    .opacity(fadeIn ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                fadeIn = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                onFinished()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Anicca. Read your energy. Understand yourself.")
    }
}
