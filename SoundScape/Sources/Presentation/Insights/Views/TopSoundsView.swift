import SwiftUI

struct TopSoundsView: View {
    let sounds: [(soundId: String, count: Int)]

    private let soundNames: [String: String] = [
        "white_noise": "White Noise",
        "pink_noise": "Pink Noise",
        "brown_noise": "Brown Noise",
        "brown_noise_deep": "Deep Brown Noise",
        "morning_birds": "Morning Birds",
        "winter_forest": "Winter Forest",
        "serene_morning": "Serene Morning",
        "rain_storm": "Rain Storm",
        "wind_ambient": "Wind Ambient",
        "campfire": "Campfire",
        "bonfire": "Bonfire"
    ]

    private let soundIcons: [String: String] = [
        "white_noise": "waveform.path",
        "pink_noise": "waveform.path",
        "brown_noise": "waveform.path",
        "brown_noise_deep": "waveform.path",
        "morning_birds": "bird.fill",
        "winter_forest": "tree.fill",
        "serene_morning": "sunrise.fill",
        "rain_storm": "cloud.rain.fill",
        "wind_ambient": "wind",
        "campfire": "flame.fill",
        "bonfire": "flame.fill"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "music.note.list")
                    .foregroundStyle(.purple)
                Text("Most Used Sounds")
                    .font(.headline)
            }

            if sounds.isEmpty {
                Text("No usage data yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(sounds.enumerated()), id: \.element.soundId) { index, sound in
                        TopSoundRowView(
                            rank: index + 1,
                            name: soundNames[sound.soundId] ?? sound.soundId.replacingOccurrences(of: "_", with: " ").capitalized,
                            icon: soundIcons[sound.soundId] ?? "waveform",
                            count: sound.count,
                            maxCount: sounds.first?.count ?? 1
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct TopSoundRowView: View {
    let rank: Int
    let name: String
    let icon: String
    let count: Int
    let maxCount: Int

    private var progress: Double {
        guard maxCount > 0 else { return 0 }
        return Double(count) / Double(maxCount)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(rankColor)
                .frame(width: 24)

            // Icon
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.purple)
                .frame(width: 28)

            // Sound name and bar
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.subheadline)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.purple.opacity(0.2))
                            .frame(height: 4)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.purple)
                            .frame(width: geometry.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }

            Spacer()

            // Count
            Text("\(count) uses")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    TopSoundsView(sounds: [
        (soundId: "brown_noise", count: 12),
        (soundId: "rain_storm", count: 8),
        (soundId: "pink_noise", count: 5),
        (soundId: "campfire", count: 3),
        (soundId: "wind_ambient", count: 2)
    ])
    .padding()
    .preferredColorScheme(.dark)
}
