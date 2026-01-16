import SwiftUI

struct SavedMixRowView: View {
    let mix: SavedMix
    let soundRepository: SoundRepositoryProtocol
    let onPlay: () -> Void
    let onRename: (String) -> Void

    @State private var showRename = false
    @State private var newName = ""

    private var soundNames: String {
        mix.sounds.compactMap { mixSound in
            soundRepository.getSound(byId: mixSound.soundId)?.name
        }.joined(separator: ", ")
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mix.name)
                    .font(.headline)

                Text("\(mix.sounds.count) sound\(mix.sounds.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !soundNames.isEmpty {
                    Text(soundNames)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                Text(mix.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.title)
                    .foregroundStyle(.purple)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                // Delete handled by onDelete in parent
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
                newName = mix.name
                showRename = true
            } label: {
                Label("Rename", systemImage: "pencil")
            }
            .tint(.blue)
        }
        .alert("Rename Mix", isPresented: $showRename) {
            TextField("Mix name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if !newName.isEmpty {
                    onRename(newName)
                }
            }
        }
    }
}

#Preview {
    List {
        SavedMixRowView(
            mix: SavedMix(
                id: UUID(),
                name: "Relaxing Evening",
                sounds: [
                    SavedMix.MixSound(soundId: "rain", volume: 0.7),
                    SavedMix.MixSound(soundId: "fire", volume: 0.5)
                ],
                createdAt: Date()
            ),
            soundRepository: SoundRepository(),
            onPlay: {},
            onRename: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
