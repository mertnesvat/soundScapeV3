import SwiftUI

struct SoundsView: View {
    @Environment(AudioEngine.self) private var audioEngine
    @State private var viewModel: SoundsViewModel?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    if let viewModel = viewModel {
                        // Category Filter
                        CategoryFilterView(selectedCategory: Binding(
                            get: { viewModel.selectedCategory },
                            set: { viewModel.selectCategory($0) }
                        ))

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
            }
            .background(Color(.systemBackground))
            .navigationTitle("Sounds")
            .onAppear {
                if viewModel == nil {
                    viewModel = SoundsViewModel(audioEngine: audioEngine)
                }
                viewModel?.loadSounds()
            }
        }
    }
}

#Preview {
    SoundsView()
        .environment(AudioEngine())
        .preferredColorScheme(.dark)
}
