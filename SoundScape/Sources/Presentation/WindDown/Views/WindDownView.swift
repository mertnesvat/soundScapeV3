import SwiftUI

// MARK: - Wind Down Content Category

enum WindDownCategory: String, CaseIterable, Identifiable {
    case featured = "Featured"
    case yogaNidra = "Yoga Nidra"
    case sleepStories = "Sleep Stories"
    case meditations = "Meditations"
    case breathing = "Breathing"
    case hypnosis = "Hypnosis"
    case affirmations = "Affirmations"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .featured: return "star.fill"
        case .yogaNidra: return "figure.mind.and.body"
        case .sleepStories: return "book.fill"
        case .meditations: return "brain.head.profile"
        case .breathing: return "wind"
        case .hypnosis: return "sparkles"
        case .affirmations: return "heart.text.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .featured: return .yellow
        case .yogaNidra: return .indigo
        case .sleepStories: return .purple
        case .meditations: return .teal
        case .breathing: return .cyan
        case .hypnosis: return .pink
        case .affirmations: return .orange
        }
    }

    var description: String {
        switch self {
        case .featured: return "Curated picks for tonight"
        case .yogaNidra: return "Deep relaxation practice"
        case .sleepStories: return "Soothing bedtime tales"
        case .meditations: return "Guided sleep meditation"
        case .breathing: return "Calming breath exercises"
        case .hypnosis: return "Gentle sleep hypnosis"
        case .affirmations: return "Positive sleep affirmations"
        }
    }
}

// MARK: - Wind Down View

struct WindDownView: View {
    @Environment(StoryProgressService.self) private var progressService

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Time to Wind Down"
        }
    }

    private var greetingSubtitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Start your day with intention"
        case 12..<17:
            return "Take a moment to relax"
        case 17..<21:
            return "Prepare for restful sleep"
        default:
            return "Let's help you drift off peacefully"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Personalized Header
                    headerSection

                    // Content Sections
                    ForEach(WindDownCategory.allCases) { category in
                        WindDownSectionView(category: category)
                    }

                    // Bottom padding for tab bar and now playing bar
                    Spacer()
                        .frame(height: 120)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Wind Down")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(greetingSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Moon icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Section View

struct WindDownSectionView: View {
    let category: WindDownCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(category.color)

                Text(category.rawValue)
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {}) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)

            // Horizontal Scroll of Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<4) { index in
                        WindDownContentCard(
                            category: category,
                            index: index
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Content Card (Placeholder)

struct WindDownContentCard: View {
    let category: WindDownCategory
    let index: Int

    private var placeholderTitles: [String] {
        switch category {
        case .featured:
            return ["Tonight's Pick", "Editor's Choice", "Most Popular", "New Release"]
        case .yogaNidra:
            return ["Deep Rest", "Body Scan", "Peaceful Sleep", "Total Relaxation"]
        case .sleepStories:
            return ["The Dream Garden", "Moonlit Forest", "Ocean Voyage", "Starlight Journey"]
        case .meditations:
            return ["Sleep Well", "Let Go", "Peaceful Mind", "Drift Away"]
        case .breathing:
            return ["4-7-8 Breath", "Box Breathing", "Calm Breath", "Sleep Breath"]
        case .hypnosis:
            return ["Deep Sleep", "Release Anxiety", "Peaceful Dreams", "Restful Night"]
        case .affirmations:
            return ["I Am Calm", "Peaceful Sleep", "Sweet Dreams", "Rest Easy"]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover placeholder with gradient
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [category.color.opacity(0.8), category.color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Title
            Text(placeholderTitles[index % placeholderTitles.count])
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)

            // Duration placeholder
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("\((index + 1) * 5 + 10) min")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .frame(width: 140)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Preview

#Preview {
    WindDownView()
        .environment(StoryProgressService())
        .preferredColorScheme(.dark)
}
