import SwiftUI

struct StoriesView: View {
    @Environment(StoryProgressService.self) private var progressService
    @State private var selectedCategory: StoryCategory? = nil

    let stories = LocalStoryDataSource.stories

    var filteredStories: [Story] {
        guard let category = selectedCategory else { return stories }
        return stories.filter { $0.category == category }
    }

    var inProgressStories: [Story] {
        let inProgressIds = progressService.inProgressStoryIds
        return stories.filter { story in
            inProgressIds.contains(story.id) && !progressService.isCompleted(story)
        }
    }

    var featuredStory: Story {
        LocalStoryDataSource.featuredStory
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Featured Story Banner
                    NavigationLink(destination: StoryPlayerView(story: featuredStory)) {
                        FeaturedStoryBanner(
                            story: featuredStory,
                            progressFraction: progressService.progressFraction(for: featuredStory)
                        )
                    }
                    .buttonStyle(.plain)

                    // Continue Listening (if any in progress)
                    if !inProgressStories.isEmpty {
                        StorySectionView(
                            title: "Continue Listening",
                            stories: inProgressStories,
                            progressService: progressService
                        )
                    }

                    // Category Filter
                    StoryCategoryFilterView(selectedCategory: $selectedCategory)

                    // All Stories header
                    Text(selectedCategory?.rawValue ?? "All Stories")
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal, 16)

                    // Story Grid
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(filteredStories) { story in
                            NavigationLink(destination: StoryPlayerView(story: story)) {
                                StoryCardView(
                                    story: story,
                                    progressFraction: progressService.progressFraction(for: story)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)

                    // Bottom padding for tab bar
                    Spacer()
                        .frame(height: 100)
                }
                .padding(.top, 8)
            }
            .navigationTitle(LocalizedStringKey("Stories"))
        }
    }
}

#Preview {
    StoriesView()
        .environment(StoryProgressService())
        .preferredColorScheme(.dark)
}
