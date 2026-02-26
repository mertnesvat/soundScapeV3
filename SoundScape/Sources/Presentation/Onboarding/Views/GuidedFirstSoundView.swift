import SwiftUI

struct GuidedFirstSoundView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(OnboardingService.self) private var onboardingService
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var currentCoachStep = 0
    @State private var showCoachMarks = false
    @State private var soundStarted = false

    private var starterSound: Sound {
        let goal = onboardingService.profile.sleepGoal
        switch goal {
        case .relaxation:
            return Sound(id: "calm_ocean", name: "Calm Ocean", category: .nature, fileName: "calm_ocean.mp3")
        case .focus:
            return Sound(id: "brown_noise", name: "Brown Noise", category: .noise, fileName: "brown_noise.mp3")
        case .meditation:
            return Sound(id: "serene_morning", name: "Serene Morning", category: .nature, fileName: "serene_morning.mp3")
        default:
            return Sound(id: "rain_storm", name: "Rain Storm", category: .weather, fileName: "rain_storm.mp3")
        }
    }

    private var coachSteps: [(icon: String, title: String, subtitle: String)] {
        [
            ("waveform.circle.fill", String(localized: "Here's your first soundscape"), String(localized: "Listen and feel the calm wash over you")),
            ("plus.circle.fill", String(localized: "Mix in more sounds"), String(localized: "Layer different sounds to create your perfect mix")),
            ("moon.fill", String(localized: "Set a sleep timer"), String(localized: "Your sounds will gently fade as you drift off"))
        ]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(String(localized: "Skip")) {
                        onContinue()
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Sound visualization
                ZStack {
                    // Animated rings
                    ForEach(0..<3, id: \.self) { ring in
                        Circle()
                            .stroke(categoryColor.opacity(0.15 - Double(ring) * 0.04), lineWidth: 2)
                            .frame(width: CGFloat(160 + ring * 60), height: CGFloat(160 + ring * 60))
                            .scaleEffect(soundStarted ? 1.05 : 0.95)
                            .animation(
                                .easeInOut(duration: 2.0 + Double(ring) * 0.5)
                                .repeatForever(autoreverses: true),
                                value: soundStarted
                            )
                    }

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [categoryColor.opacity(0.4), categoryColor.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: starterSound.category.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(categoryColor)
                }
                .padding(.bottom, 32)

                // Sound name
                Text(starterSound.name)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                Text(String(localized: "Now playing"))
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                // Coach marks area
                if showCoachMarks {
                    coachMarkCard
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }

                // Continue / Next button
                OnboardingButton(
                    title: coachButtonTitle,
                    action: advanceCoach
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            playStarterSound()
        }
    }

    private var categoryColor: Color {
        switch starterSound.category {
        case .weather: return .blue
        case .nature: return .green
        case .noise: return .purple
        default: return .purple
        }
    }

    private var coachButtonTitle: String {
        if !showCoachMarks {
            return String(localized: "Continue")
        }
        if currentCoachStep < coachSteps.count - 1 {
            return String(localized: "Next")
        }
        return String(localized: "Continue")
    }

    private var coachMarkCard: some View {
        HStack(spacing: 16) {
            Image(systemName: coachSteps[currentCoachStep].icon)
                .font(.system(size: 28))
                .foregroundColor(categoryColor)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(coachSteps[currentCoachStep].title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(coachSteps[currentCoachStep].subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
        )
        .id(currentCoachStep)
    }

    private func playStarterSound() {
        audioEngine.play(sound: starterSound)
        withAnimation(.easeInOut(duration: 0.5)) {
            soundStarted = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showCoachMarks = true
            }
        }
    }

    private func advanceCoach() {
        if !showCoachMarks {
            withAnimation {
                showCoachMarks = true
            }
            return
        }

        if currentCoachStep < coachSteps.count - 1 {
            withAnimation {
                currentCoachStep += 1
            }
        } else {
            onContinue()
        }
    }
}

#Preview {
    GuidedFirstSoundView(
        onContinue: {},
        onBack: {}
    )
    .environment(AudioEngine())
    .environment(OnboardingService())
}
