import SwiftUI

struct CommunityMixCardView: View {
    let mix: CommunityMix
    let onPlay: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with mix name and creator
            VStack(alignment: .leading, spacing: 4) {
                Text(mix.name)
                    .font(.headline)
                    .lineLimit(1)

                Text("by \(mix.creatorName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Stats row
            HStack(spacing: 16) {
                StatBadge(icon: "waveform", value: "\(mix.soundCount) sounds")
                StatBadge(icon: "play.fill", value: formatCount(mix.playCount))
                StatBadge(icon: "heart.fill", value: formatCount(mix.upvotes))
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(mix.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                Button(action: onPlay) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: onSave) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.2))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

private struct StatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(value)
        }
    }
}

#Preview {
    CommunityMixCardView(
        mix: CommunityMix(
            id: UUID(),
            name: "Rainy Day Focus",
            creatorName: "SleepyPanda",
            sounds: [
                .init(soundId: "rain_storm", volume: 0.6),
                .init(soundId: "brown_noise", volume: 0.3)
            ],
            playCount: 12500,
            upvotes: 843,
            tags: ["focus", "rain", "productive"],
            category: .focus,
            createdAt: Date(),
            isFeatured: true
        ),
        onPlay: {},
        onSave: {}
    )
    .padding()
    .preferredColorScheme(.dark)
}
