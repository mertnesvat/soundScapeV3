import SwiftUI

struct StoriesView: View {
    @Environment(StoryProgressService.self) private var progressService

    private let stories = LocalStoryDataSource.stories

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.surface.ignoresSafeArea()

                if stories.isEmpty {
                    Text(LocalizedStringKey("No stories yet."))
                        .font(.body.weight(DesignTokens.font.body))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .multilineTextAlignment(.center)
                } else {
                    List {
                        ForEach(stories) { story in
                            NavigationLink {
                                StoryPlayerView(story: story)
                            } label: {
                                row(for: story)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .accessibilityLabel(Text("Play \(story.title)"))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(LocalizedStringKey("Stories"))
        }
    }

    private func row(for story: Story) -> some View {
        HStack(spacing: DesignTokens.padding.standard) {
            VStack(alignment: .leading, spacing: 4) {
                Text(story.title)
                    .font(.body.weight(DesignTokens.font.body))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(story.formattedDuration)
                    .font(.caption.weight(DesignTokens.font.body))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "play.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(DesignTokens.accent)
                .accessibilityHidden(true)
        }
        .padding(.vertical, DesignTokens.padding.compact)
        .contentShape(Rectangle())
    }
}

#Preview {
    StoriesView()
        .environment(StoryProgressService())
        .preferredColorScheme(.dark)
}
