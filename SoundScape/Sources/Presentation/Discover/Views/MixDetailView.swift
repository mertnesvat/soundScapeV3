import SwiftUI

struct MixDetailView: View {
    let mix: CommunityMix
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(SavedMixesService.self) private var savedMixesService
    @Environment(\.dismiss) private var dismiss
    @State private var showingSavedAlert = false

    private let allSounds = LocalSoundDataSource.shared.getAllSounds()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Stats
                statsSection

                // Tags
                tagsSection

                // Sounds list
                soundsSection

                // Action buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle(mix.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert(LocalizedStringKey("Saved!"), isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\"\(mix.name)\" has been saved to My Mixes")
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category badge
            HStack {
                Image(systemName: mix.category.icon)
                Text(mix.category.rawValue)
            }
            .font(.caption)
            .foregroundStyle(categoryColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(categoryColor.opacity(0.2))
            .clipShape(Capsule())

            // Mix name
            Text(mix.name)
                .font(.largeTitle)
                .fontWeight(.bold)

            // Creator
            HStack {
                Image(systemName: "person.circle.fill")
                Text("by \(mix.creatorName)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // Date
            Text("Created \(mix.createdAt, style: .relative) ago")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 24) {
            StatItem(icon: "play.fill", value: formatCount(mix.playCount), label: "Plays")
            StatItem(icon: "heart.fill", value: formatCount(mix.upvotes), label: "Upvotes")
            StatItem(icon: "waveform", value: "\(mix.soundCount)", label: "Sounds")
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(mix.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var soundsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sounds in this mix")
                .font(.headline)

            ForEach(mix.sounds, id: \.soundId) { mixSound in
                if let sound = allSounds.first(where: { $0.id == mixSound.soundId }) {
                    HStack {
                        Image(systemName: sound.category.icon)
                            .font(.title3)
                            .foregroundStyle(Color(sound.category.color))
                            .frame(width: 40, height: 40)
                            .background(Color(sound.category.color).opacity(0.2))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(sound.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(sound.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Volume indicator
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                            Text("\(Int(mixSound.volume * 100))%")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    HStack {
                        Image(systemName: "waveform")
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())

                        Text(mixSound.soundId)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Play button
            Button(action: playMix) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Play Mix")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.purple)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Save button
            Button(action: saveMix) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save to My Mixes")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.2))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            // Share button (mock)
            Button(action: {}) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.2))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.top, 8)
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

    private func playMix() {
        // Stop all current sounds
        audioEngine.stopAll()

        // Play each sound in the mix
        for mixSound in mix.sounds {
            if let sound = allSounds.first(where: { $0.id == mixSound.soundId }) {
                audioEngine.play(sound: sound)
                audioEngine.setVolume(mixSound.volume, for: sound.id)
            }
        }
    }

    private func saveMix() {
        // Convert to active sounds for saving
        var activeSounds: [ActiveSound] = []
        for mixSound in mix.sounds {
            if let sound = allSounds.first(where: { $0.id == mixSound.soundId }) {
                activeSounds.append(ActiveSound(
                    id: sound.id,
                    sound: sound,
                    volume: mixSound.volume,
                    isPlaying: false
                ))
            }
        }

        if !activeSounds.isEmpty {
            savedMixesService.saveMix(name: mix.name, sounds: activeSounds)
            showingSavedAlert = true
        }
    }
}

private struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(value)
                    .fontWeight(.bold)
            }
            .font(.title3)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Simple flow layout for tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return arrangeSubviews(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let positions = arrangeSubviews(sizes: sizes, containerWidth: bounds.width).positions

        for (index, subview) in subviews.enumerated() {
            let point = CGPoint(
                x: bounds.minX + positions[index].x,
                y: bounds.minY + positions[index].y
            )
            subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
        }
    }

    private func arrangeSubviews(sizes: [CGSize], containerWidth: CGFloat) -> (positions: [CGPoint], size: CGSize) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += maxHeight + spacing
                maxHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            maxHeight = max(maxHeight, size.height)
            currentX += size.width + spacing
            maxWidth = max(maxWidth, currentX - spacing)
        }

        return (positions, CGSize(width: maxWidth, height: currentY + maxHeight))
    }
}

#Preview {
    NavigationStack {
        MixDetailView(
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
                createdAt: Date().addingTimeInterval(-86400 * 7),
                isFeatured: true
            )
        )
    }
    .environment(AudioEngine())
    .environment(SavedMixesService())
    .preferredColorScheme(.dark)
}
