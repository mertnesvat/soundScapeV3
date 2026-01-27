import SwiftUI

struct OnboardingAnalysisView: View {
    let isActive: Bool
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var currentMessageIndex = 0
    @State private var hasStarted = false
    @State private var hasCompleted = false
    @State private var timer: Timer?

    private let messages = [
        "Reviewing your sleep goals...",
        "Identifying your challenges...",
        "Finding the perfect sounds...",
        "Creating your personalized plan..."
    ]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 160, height: 160)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.05), value: progress)

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }

            // Status message
            Text(messages[min(currentMessageIndex, messages.count - 1)])
                .font(.headline)
                .foregroundColor(.gray)
                .animation(.easeInOut, value: currentMessageIndex)

            Spacer()
        }
        .background(Color.black)
        .onChange(of: isActive) { _, newValue in
            if newValue {
                resetAndStart()
            } else {
                // Clean up when becoming inactive
                stopAnalysis()
            }
        }
        .onAppear {
            // Also try onAppear as backup
            if isActive && !hasStarted {
                resetAndStart()
            }
        }
        .onDisappear {
            stopAnalysis()
        }
    }

    private func stopAnalysis() {
        timer?.invalidate()
        timer = nil
    }

    private func resetAndStart() {
        // Prevent multiple starts or restarting after completion
        guard !hasStarted, !hasCompleted else { return }

        // Reset state
        progress = 0
        currentMessageIndex = 0
        hasStarted = true

        // Stop any existing timer
        stopAnalysis()

        // Small delay to ensure view is visible before starting
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            startAnalysis()
        }
    }

    private func startAnalysis() {
        let totalDuration: Double = 4.0
        let updateInterval: Double = 0.05
        var elapsed: Double = 0

        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { t in
            elapsed += updateInterval
            let newProgress = min(elapsed / totalDuration, 1.0)

            withAnimation(.linear(duration: updateInterval)) {
                progress = newProgress
            }

            // Update message based on progress
            let messageIndex = min(Int(newProgress * Double(messages.count)), messages.count - 1)
            if messageIndex != currentMessageIndex {
                withAnimation {
                    currentMessageIndex = messageIndex
                }
            }

            // Complete when done
            if elapsed >= totalDuration {
                t.invalidate()
                timer = nil
                hasCompleted = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    OnboardingAnalysisView(isActive: true, onComplete: {})
}
