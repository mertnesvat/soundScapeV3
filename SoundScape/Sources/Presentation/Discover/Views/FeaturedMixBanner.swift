import SwiftUI

struct FeaturedMixBanner: View {
    let mix: CommunityMix
    let onPlay: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Featured badge
            HStack {
                Image(systemName: "star.fill")
                Text("Mix of the Week")
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(.yellow)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.yellow.opacity(0.2))
            .clipShape(Capsule())
            .padding(.bottom, 12)

            // Mix name
            Text(mix.name)
                .font(.title)
                .fontWeight(.bold)
                .lineLimit(2)

            // Creator
            Text("by \(mix.creatorName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            // Stats
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                    Text(formatCount(mix.playCount))
                }
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                    Text(formatCount(mix.upvotes))
                }
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                    Text("\(mix.soundCount) sounds")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.top, 8)

            // Tags
            HStack(spacing: 8) {
                ForEach(mix.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }
            .padding(.top, 8)

            // Buttons
            HStack(spacing: 12) {
                Button(action: onPlay) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Play Now")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: onSave) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.headline)
                        .padding(14)
                        .background(Color.gray.opacity(0.2))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.top, 16)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

#Preview {
    FeaturedMixBanner(
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
    .preferredColorScheme(.dark)
}
