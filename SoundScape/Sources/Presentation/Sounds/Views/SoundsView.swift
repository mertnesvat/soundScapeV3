import SwiftUI

struct SoundsView: View {
    @State private var viewModel = SoundsViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Category Filter
                    CategoryFilterView(selectedCategory: $viewModel.selectedCategory)

                    // Sound Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredSounds) { sound in
                            SoundCardView(
                                sound: sound,
                                isPlaying: viewModel.isPlaying(sound),
                                onTogglePlay: {
                                    viewModel.togglePlay(for: sound)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Sounds")
            .onAppear {
                viewModel.loadSounds()
            }
        }
    }
}

#Preview {
    SoundsView()
        .preferredColorScheme(.dark)
}
