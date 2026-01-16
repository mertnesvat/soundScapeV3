import SwiftUI

struct MixSectionView: View {
    let title: String
    let mixes: [CommunityMix]
    let onPlayMix: (CommunityMix) -> Void
    let onSaveMix: (CommunityMix) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("\(mixes.count) mixes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            // Horizontal scroll of mix cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(mixes) { mix in
                        MixSectionCard(
                            mix: mix,
                            onPlay: { onPlayMix(mix) },
                            onSave: { onSaveMix(mix) }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct MixSectionCard: View {
    let mix: CommunityMix
    let onPlay: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Mix icon/visual
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [categoryColor.opacity(0.4), categoryColor.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 100)

                Image(systemName: mix.category.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(categoryColor)
            }

            // Mix name
            Text(mix.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            // Creator
            Text("by \(mix.creatorName)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Stats
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Image(systemName: "play.fill")
                    Text(formatCount(mix.playCount))
                }
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                    Text(formatCount(mix.upvotes))
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            // Play button
            Button(action: onPlay) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play")
                }
                .font(.caption)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.purple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .frame(width: 140)
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryColor: Color {
        switch mix.category {
        case .trending: return .orange
        case .popular: return .yellow
        case .sleep: return .indigo
        case .focus: return .blue
        case .nature: return .green
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        }
        return "\(count)"
    }
}

#Preview {
    MixSectionView(
        title: "Trending",
        mixes: LocalCommunityDataSource.shared.trendingMixes,
        onPlayMix: { _ in },
        onSaveMix: { _ in }
    )
    .preferredColorScheme(.dark)
}
