import SwiftUI

struct StorySectionView: View {
    let title: String
    let stories: [Story]
    let progressService: StoryProgressService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(stories) { story in
                        NavigationLink(destination: StoryPlayerView(story: story)) {
                            StoryCardView(
                                story: story,
                                progressFraction: progressService.progressFraction(for: story)
                            )
                            .frame(width: 160)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

#Preview {
    NavigationStack {
        StorySectionView(
            title: "Continue Listening",
            stories: Array(LocalStoryDataSource.stories.prefix(4)),
            progressService: StoryProgressService()
        )
    }
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
}
