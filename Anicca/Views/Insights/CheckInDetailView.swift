import SwiftUI

struct CheckInDetailView: View {
    let checkIn: CheckIn

    var body: some View {
        ZStack {
            AniccaTheme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(checkIn.createdAt.humanReadable).anicca(.headline)
                        Text("\(checkIn.sortedEntries.count) emotions logged").anicca(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .aniccaCard()
 
                    ForEach(checkIn.sortedEntries) { entry in
                        emotionRow(entry)
                    }

                    if let note = checkIn.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                            Text("Note").anicca(.subheadline)
                            Text(note).anicca(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .aniccaCard()
                    }
                }
                .padding(AniccaTheme.Spacing.s20)
            }
        }
        .navigationTitle("Check-in detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func emotionRow(_ entry: EmotionEntry) -> some View {
        HStack(spacing: AniccaTheme.Spacing.s12) {
            Circle().fill(entry.energyCenter.color).frame(width: 14, height: 14)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.emotionName).anicca(.body)
                Text(entry.energyCenter.displayName).anicca(.caption)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= entry.intensity ? entry.energyCenter.color : AniccaTheme.textMuted.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(AniccaTheme.Spacing.s12)
        .aniccaCard(padding: AniccaTheme.Spacing.s12)
        .accessibilityLabel("\(entry.emotionName), intensity \(entry.intensity) of 5, \(entry.energyCenter.displayName) center")
    }
}
