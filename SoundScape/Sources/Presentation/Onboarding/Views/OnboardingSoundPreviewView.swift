import SwiftUI

struct OnboardingSoundPreviewView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(OnboardingService.self) private var onboardingService
    let intent: UserIntent
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var hasStartedPlaying = false

    private var sounds: [Sound] {
        onboardingService.soundsForIntent(intent)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Skip button
            HStack {
                Spacer()
                Button(String(localized: "Skip")) {
                    onSkip()
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Animated waveform icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: "waveform")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.variableColor.iterative, isActive: audioEngine.isAnyPlaying)
            }
            .padding(.bottom, 32)

            // Headline
            Text(String(localized: "Your \(intent.localizedTitle) Mix"))
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.bottom, 12)

            // Sound names
            Text(sounds.map(\.name).joined(separator: " + "))
                .font(.body)
                .foregroundColor(.gray)
                .padding(.bottom, 32)

            // Sound cards
            VStack(spacing: 12) {
                ForEach(sounds) { sound in
                    SoundPreviewRow(sound: sound, isPlaying: audioEngine.isPlaying(soundId: sound.id))
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Continue button
            OnboardingButton(
                title: String(localized: "Continue"),
                action: onContinue
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.black)
        .onAppear {
            if !hasStartedPlaying {
                hasStartedPlaying = true
                for sound in sounds {
                    audioEngine.play(sound: sound)
                }
            }
        }
    }
}

struct SoundPreviewRow: View {
    let sound: Sound
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: sound.category.icon)
                .font(.title3)
                .foregroundColor(Color(sound.category.color))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(sound.category.color).opacity(0.15))
                )

            Text(sound.name)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()

            if isPlaying {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundColor(.purple)
                    .symbolEffect(.variableColor.iterative, isActive: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview {
    OnboardingSoundPreviewView(
        intent: .sleep,
        onContinue: {},
        onSkip: {}
    )
    .environment(AudioEngine())
    .environment(OnboardingService())
}
