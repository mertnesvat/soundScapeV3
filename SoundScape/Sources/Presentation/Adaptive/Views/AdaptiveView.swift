import SwiftUI

struct AdaptiveView: View {
    @Environment(AdaptiveSessionService.self) private var adaptiveService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if adaptiveService.isActive {
                        ActiveAdaptiveSessionView()
                    } else {
                        modeSelectionView
                    }
                }
                .padding()
            }
            .navigationTitle("Adaptive")
            .background(Color(.systemBackground))
        }
    }

    private var modeSelectionView: some View {
        VStack(spacing: 20) {
            Text("Choose an Adaptive Mode")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(AdaptiveMode.allCases) { mode in
                AdaptiveModeCardView(mode: mode) {
                    adaptiveService.start(mode: mode)
                }
            }
        }
    }
}

#Preview {
    let audioEngine = AudioEngine()
    return AdaptiveView()
        .environment(AdaptiveSessionService(audioEngine: audioEngine))
        .preferredColorScheme(.dark)
}
