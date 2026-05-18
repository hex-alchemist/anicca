import SwiftUI

struct RadarChartData: Equatable {
    let scores: [EnergyCenter: Double]   // 0.0–1.0
}

struct RadarChartView: View {
    let data: RadarChartData

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 - 30

            ZStack {
                // Grid rings
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
                    polygon(center: center, radius: radius * fraction)
                        .stroke(AniccaTheme.textMuted.opacity(0.25), lineWidth: 1)
                }

                // Axis lines
                ForEach(0..<7) { i in
                    let angle = angleFor(index: i)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(center: center, radius: radius, angle: angle))
                    }
                    .stroke(AniccaTheme.textMuted.opacity(0.2), lineWidth: 1)
                }

                // Data polygon
                dataPath(center: center, radius: radius)
                    .fill(AniccaTheme.brandPrimary.opacity(0.25))
                    .animation(AniccaTheme.springAnimation, value: data)

                dataPath(center: center, radius: radius)
                    .stroke(AniccaTheme.brandPrimary, lineWidth: 2)
                    .animation(AniccaTheme.springAnimation, value: data)

                // Vertex dots
                ForEach(0..<EnergyCenter.allCases.count, id: \.self) { i in
                    let centerType = EnergyCenter.allCases[i]
                    let score = data.scores[centerType] ?? 0
                    let angle = angleFor(index: i)
                    let p = point(center: center, radius: radius * CGFloat(score), angle: angle)
                    Circle()
                        .fill(centerType.color)
                        .frame(width: 8, height: 8)
                        .position(p)
                        .animation(AniccaTheme.springAnimation, value: score)
                }

                // Labels
                ForEach(0..<EnergyCenter.allCases.count, id: \.self) { i in
                    let centerType = EnergyCenter.allCases[i]
                    let angle = angleFor(index: i)
                    let labelPoint = point(center: center, radius: radius + 22, angle: angle)
                    HStack(spacing: 4) {
                        Circle().fill(centerType.color).frame(width: 8, height: 8)
                        Text(centerType.displayName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(AniccaTheme.textSecondary)
                    }
                    .position(labelPoint)
                }
            }
        }
        .equatable(by: data)
    }

    private func angleFor(index: Int) -> CGFloat {
        let total = CGFloat(EnergyCenter.allCases.count)
        return -CGFloat.pi / 2 + (CGFloat(index) * 2 * CGFloat.pi / total)
    }

    private func point(center: CGPoint, radius: CGFloat, angle: CGFloat) -> CGPoint {
        CGPoint(x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle))
    }

    private func polygon(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for i in 0..<EnergyCenter.allCases.count {
                let p = point(center: center, radius: radius, angle: angleFor(index: i))
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }

    private func dataPath(center: CGPoint, radius: CGFloat) -> Path {
        Path { path in
            for i in 0..<EnergyCenter.allCases.count {
                let centerType = EnergyCenter.allCases[i]
                let score = data.scores[centerType] ?? 0
                let p = point(center: center, radius: radius * CGFloat(score), angle: angleFor(index: i))
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }
}

private struct EquatableModifier<Value: Equatable>: ViewModifier {
    let value: Value
    func body(content: Content) -> some View { content }
}

private extension View {
    func equatable<V: Equatable>(by value: V) -> some View {
        modifier(EquatableModifier(value: value))
    }
}
