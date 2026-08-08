import SwiftUI

/// Editorial saved-mixes sheet — cream canvas with a thick black `SAVED MIXES`
/// headline and a vertical stack of peach-tile rows, each carrying an oversized
/// index numeral, a play affordance, and an `n sounds · created MMM d` subtitle.
/// The currently-loaded mix swaps its peach tile for a saturated orange tile
/// with white text. Replaces the legacy `.insetGrouped` list layout.
struct SavedMixesView: View {
    @Environment(SavedMixesService.self) private var mixesService
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(\.dismiss) private var dismiss

    @State private var loadedMixId: UUID?
    @State private var renameTarget: SavedMix?
    @State private var renameDraft: String = ""

    private let soundRepository: SoundRepositoryProtocol = SoundRepository()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                editorialHeader

                if mixesService.mixes.isEmpty {
                    emptyState
                } else {
                    mixList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Tokens.colorCream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .alert("Rename Mix", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("Mix name", text: $renameDraft)
                Button("Cancel", role: .cancel) { renameTarget = nil }
                Button("Save") {
                    if let mix = renameTarget, !renameDraft.trimmingCharacters(in: .whitespaces).isEmpty {
                        mixesService.renameMix(mix, to: renameDraft)
                    }
                    renameTarget = nil
                }
            }
        }
    }

    // MARK: - Header (thick black-on-cream SAVED MIXES)

    private var editorialHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("SAVED MIXES")
                .font(.system(size: Tokens.headlineSize, weight: .bold, design: .default))
                .tracking(0.5)
                .foregroundColor(Tokens.colorInk)
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Tokens.colorInk)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close saved mixes")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Mix list

    private var mixList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(mixesService.mixes.enumerated()), id: \.element.id) { offset, mix in
                    SavedMixEditorialRow(
                        mix: mix,
                        index: offset + 1,
                        isLoaded: loadedMixId == mix.id,
                        soundRepository: soundRepository,
                        onPlay: { loadMix(mix) },
                        onRename: {
                            renameDraft = mix.name
                            renameTarget = mix
                        },
                        onDelete: {
                            if loadedMixId == mix.id { loadedMixId = nil }
                            mixesService.deleteMix(mix)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(Tokens.colorInk.opacity(0.4))
            Text("No Saved Mixes")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Tokens.colorInk)
            Text("Save your current sound mix from the Mixer")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Tokens.colorInk.opacity(0.6))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func loadMix(_ mix: SavedMix) {
        audioEngine.stopAll()
        loadedMixId = mix.id

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            for mixSound in mix.sounds {
                if let sound = soundRepository.getSound(byId: mixSound.soundId) {
                    audioEngine.play(sound: sound)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        audioEngine.setVolume(mixSound.volume, for: sound.id)
                    }
                }
            }
        }
    }
}

// MARK: - Editorial row

private struct SavedMixEditorialRow: View {
    let mix: SavedMix
    let index: Int
    let isLoaded: Bool
    let soundRepository: SoundRepositoryProtocol
    let onPlay: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false

    private var tileBackground: Color {
        isLoaded ? Tokens.colorOrange : Tokens.colorPeach
    }

    private var primaryText: Color {
        isLoaded ? .white : Tokens.colorInk
    }

    private var subtitleColor: Color {
        isLoaded ? Color.white.opacity(0.75) : Tokens.colorInk.opacity(0.6)
    }

    private var formattedIndex: String {
        String(format: "%02d", index)
    }

    private var subtitle: String {
        let soundCount = mix.sounds.count
        let countText = "\(soundCount) sound\(soundCount == 1 ? "" : "s")"
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateText = formatter.string(from: mix.createdAt)
        return "\(countText) · created \(dateText)"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(formattedIndex)
                    .font(.system(size: 56, weight: .bold, design: .default))
                    .foregroundColor(primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(mix.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(primaryText)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(subtitleColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(primaryText)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(primaryText, lineWidth: 1.5)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Play \(mix.name)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous)
                .fill(tileBackground)
        )
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(Tokens.tactilePress, value: isPressed)
        .contentShape(RoundedRectangle(cornerRadius: Tokens.radiusTile, style: .continuous))
        .onTapGesture { onPlay() }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .contextMenu {
            Button("Rename", action: onRename)
            Button("Delete", role: .destructive, action: onDelete)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mix.name), \(subtitle)\(isLoaded ? ", currently loaded" : "")")
    }
}

#Preview {
    SavedMixesView()
        .environment(SavedMixesService())
        .environment(AudioEngine())
}
