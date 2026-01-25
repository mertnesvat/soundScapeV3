import SwiftUI

/// A horizontal scroll section showing content the user has started but not completed
/// Shows cards with progress indicators for quick resume
struct ContinueListeningSection: View {
    let incompleteContent: [SleepContent]
    let progressForContent: (String) -> Double
    let onContentTap: (SleepContent) -> Void

    @Environment(AppearanceService.self) private var appearanceService

    var body: some View {
        if !incompleteContent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader
                contentScroll
            }
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundColor(.blue)

            Text("Continue Listening")
                .font(.title3)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Content Scroll

    private var contentScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(incompleteContent) { content in
                    ContinueListeningCard(
                        content: content,
                        progress: progressForContent(content.id),
                        onTap: { onContentTap(content) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Continue Listening Card

/// A compact card for continue listening items with prominent progress indicator
struct ContinueListeningCard: View {
    let content: SleepContent
    let progress: Double
    let onTap: () -> Void

    @Environment(AppearanceService.self) private var appearanceService

    private var categoryColor: Color {
        content.contentType.color
    }

    private var remainingTime: String {
        let remaining = content.duration * (1 - progress)
        let minutes = Int(remaining / 60)
        if minutes < 1 {
            return "< 1 min left"
        } else if minutes == 1 {
            return "1 min left"
        } else {
            return "\(minutes) min left"
        }
    }

    private var progressPercentage: Int {
        Int(progress * 100)
    }

    private var cardBackgroundColor: Color {
        if appearanceService.isOLEDModeEnabled {
            return Color(.systemGray6).opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Circular progress with icon
                circularProgress

                // Content info
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text(content.contentType.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Text(remainingTime)
                        .font(.caption)
                        .foregroundColor(categoryColor)
                        .fontWeight(.medium)
                }

                Spacer(minLength: 8)

                // Play button
                Image(systemName: "play.fill")
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(categoryColor)
                    )
            }
            .padding(12)
            .frame(width: 220)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Circular Progress

    private var circularProgress: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(categoryColor.opacity(0.2), lineWidth: 4)
                .frame(width: 50, height: 50)

            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(categoryColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))

            // Icon
            Image(systemName: content.contentType.icon)
                .font(.system(size: 18))
                .foregroundColor(categoryColor)
        }
    }
}

// MARK: - Preview

#Preview("With Content") {
    VStack(spacing: 24) {
        ContinueListeningSection(
            incompleteContent: [
                SleepContent(
                    id: "preview-1",
                    title: "Complete Yoga Nidra",
                    narrator: "Guided Voice",
                    duration: 600,
                    contentType: .yogaNidra,
                    description: "Full yoga nidra journey",
                    audioFileName: "yoga_nidra_sleep_10min.mp3",
                    coverImageName: nil
                ),
                SleepContent(
                    id: "preview-2",
                    title: "The Sleepy Forest",
                    narrator: "Sarah Moon",
                    duration: 1200,
                    contentType: .sleepStory,
                    description: "A gentle tale",
                    audioFileName: nil,
                    coverImageName: nil
                )
            ],
            progressForContent: { id in
                id == "preview-1" ? 0.65 : 0.25
            },
            onContentTap: { _ in }
        )
    }
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
}

#Preview("Empty") {
    ContinueListeningSection(
        incompleteContent: [],
        progressForContent: { _ in 0 },
        onContentTap: { _ in }
    )
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
    .environment(AppearanceService())
}
