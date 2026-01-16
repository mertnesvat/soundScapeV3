import SwiftUI
import AVFoundation

struct SoundPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSoundId: String

    @State private var previewPlayer: AVAudioPlayer?
    @State private var playingId: String?

    private let sounds = LocalSoundDataSource.shared.getAllSounds()

    // Filter sounds appropriate for alarms (nature sounds work best)
    private var alarmSounds: [Sound] {
        sounds.filter { sound in
            // Include nature sounds and some gentle options
            sound.category == .nature ||
            sound.id == "campfire" ||
            sound.id == "rain_storm"
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(alarmSounds) { sound in
                    HStack {
                        Button {
                            togglePreview(for: sound)
                        } label: {
                            Image(systemName: playingId == sound.id ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.purple)
                        }
                        .buttonStyle(.plain)

                        Text(sound.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        if selectedSoundId == sound.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.purple)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSoundId = sound.id
                    }
                }
            } header: {
                Text("Wake-up Sounds")
            } footer: {
                Text("Tap play to preview, tap row to select")
            }
        }
        .navigationTitle("Alarm Sound")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    stopPreview()
                    dismiss()
                }
            }
        }
        .onDisappear {
            stopPreview()
        }
    }

    private func togglePreview(for sound: Sound) {
        if playingId == sound.id {
            stopPreview()
        } else {
            playPreview(for: sound)
        }
    }

    private func playPreview(for sound: Sound) {
        stopPreview()

        guard let url = Bundle.main.url(
            forResource: sound.fileName.replacingOccurrences(of: ".mp3", with: ""),
            withExtension: "mp3"
        ) else { return }

        do {
            previewPlayer = try AVAudioPlayer(contentsOf: url)
            previewPlayer?.volume = 0.5
            previewPlayer?.play()
            playingId = sound.id

            // Auto-stop after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak previewPlayer] in
                previewPlayer?.stop()
                if self.playingId == sound.id {
                    self.playingId = nil
                }
            }
        } catch {
            print("Preview error: \(error.localizedDescription)")
        }
    }

    private func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        playingId = nil
    }
}

#Preview {
    NavigationStack {
        SoundPickerView(selectedSoundId: .constant("morning_birds"))
    }
    .preferredColorScheme(.dark)
}
