import SwiftUI

struct OnboardingCustomPlanView: View {
    @Environment(OnboardingService.self) private var onboardingService
    let onContinue: () -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Headline
                VStack(spacing: 8) {
                    Text("Your Personal\nSleep Plan")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)

                    Text("Based on your goals and challenges")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)

                // Recommended sounds section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recommended for you")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recommendedSounds, id: \.name) { sound in
                                RecommendedSoundCard(
                                    name: sound.name,
                                    category: sound.category,
                                    icon: sound.icon
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 32)

                // Routine suggestions
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your sleep routine")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)

                    VStack(spacing: 12) {
                        RoutineStepCard(
                            number: 1,
                            title: "Start 30 minutes before bed",
                            description: "Give your mind time to unwind"
                        )
                        RoutineStepCard(
                            number: 2,
                            title: "Use the sleep timer",
                            description: "Sounds fade as you drift off"
                        )
                        RoutineStepCard(
                            number: 3,
                            title: "Track your progress",
                            description: "See improvement in Insights"
                        )
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 32)

                // Personalized message
                Text(personalizedMessage)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                // Continue button
                OnboardingButton(title: "Start My Journey", action: onContinue)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .background(Color.black)
    }

    private var recommendedSounds: [(name: String, category: String, icon: String)] {
        var sounds: [(name: String, category: String, icon: String)] = []
        let challenges = onboardingService.profile.sleepChallenges

        if challenges.contains(.racingThoughts) || challenges.contains(.anxiety) {
            sounds.append(("Rain Storm", "Weather", "cloud.rain.fill"))
            sounds.append(("Brown Noise", "Noise", "waveform"))
        }

        if challenges.contains(.noise) {
            sounds.append(("White Noise", "Noise", "waveform.path"))
            sounds.append(("Pink Noise", "Noise", "waveform"))
        }

        if challenges.contains(.stress) {
            sounds.append(("Calm Ocean", "Nature", "water.waves"))
            sounds.append(("Forest", "Nature", "leaf.fill"))
        }

        // Ensure at least 3 sounds
        if sounds.count < 3 {
            sounds.append(("Night Wildlife", "Nature", "bird.fill"))
            sounds.append(("Campfire", "Fire", "flame.fill"))
        }

        return Array(sounds.prefix(4))
    }

    private var personalizedMessage: String {
        switch onboardingService.profile.sleepGoal {
        case .fallAsleep:
            return "Your calming sounds are ready to help you drift off peacefully."
        case .stayAsleep:
            return "Consistent background sounds will help you maintain deep sleep all night."
        case .wakeRefreshed:
            return "Quality sleep leads to refreshed mornings. Let's get started."
        case .relaxation:
            return "Your stress-relief soundscape awaits. Time to unwind."
        case .focus:
            return "Background sounds can boost concentration. Your focus mix is ready."
        case .meditation:
            return "Create the perfect atmosphere for mindfulness and inner peace."
        case .none:
            return "Your personalized sleep experience is ready to begin."
        }
    }
}

struct RecommendedSoundCard: View {
    let name: String
    let category: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.purple)
            }

            VStack(spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(category)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 100)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct RoutineStepCard: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingCustomPlanView(
        onContinue: {},
        onBack: {}
    )
    .environment(OnboardingService())
}
