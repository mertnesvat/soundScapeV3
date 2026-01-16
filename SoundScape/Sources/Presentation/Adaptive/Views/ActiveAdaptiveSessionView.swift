import SwiftUI

struct ActiveAdaptiveSessionView: View {
    @Environment(AdaptiveSessionService.self) private var adaptiveService

    var body: some View {
        VStack(spacing: 24) {
            // Header with mode info
            headerSection

            // Current phase card
            if let phase = adaptiveService.currentPhase {
                currentPhaseCard(phase: phase)
            }

            // Overall progress
            progressSection

            // Timeline of phases
            phaseTimeline

            Spacer()

            // Stop button
            stopButton
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            if let mode = adaptiveService.currentMode {
                Image(systemName: mode.icon)
                    .font(.system(size: 48))
                    .foregroundColor(.purple)

                Text(mode.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Session Active")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding(.top)
    }

    private func currentPhaseCard(phase: AdaptivePhase) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current Phase")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Phase \(adaptiveService.currentPhaseIndex + 1) of \(adaptiveService.currentMode?.phases.count ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.name)
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text(soundsDescription(for: phase))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Time remaining in phase
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formatTime(adaptiveService.phaseTimeRemaining))
                        .font(.system(size: 28, weight: .semibold, design: .monospaced))
                        .foregroundColor(.purple)
                    Text("remaining")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Phase progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purple.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * adaptiveService.phaseProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var progressSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Overall Progress")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(adaptiveService.progress * 100))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.purple.opacity(0.2))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .purple.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * adaptiveService.progress, height: 12)
                }
            }
            .frame(height: 12)

            HStack {
                Text(formatTime(adaptiveService.elapsedTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatTime(adaptiveService.totalTimeInSeconds))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var phaseTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.subheadline)
                .fontWeight(.medium)

            if let mode = adaptiveService.currentMode {
                ForEach(Array(mode.phases.enumerated()), id: \.element.id) { index, phase in
                    HStack(spacing: 12) {
                        // Status indicator
                        ZStack {
                            Circle()
                                .fill(phaseStatusColor(for: index))
                                .frame(width: 24, height: 24)

                            if index < adaptiveService.currentPhaseIndex {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            } else if index == adaptiveService.currentPhaseIndex {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                            }
                        }

                        Text(phase.name)
                            .font(.subheadline)
                            .foregroundColor(index <= adaptiveService.currentPhaseIndex ? .primary : .secondary)

                        Spacer()

                        Text("\(phase.duration)m")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .opacity(index < adaptiveService.currentPhaseIndex ? 0.6 : 1.0)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var stopButton: some View {
        Button {
            adaptiveService.stop()
        } label: {
            HStack {
                Image(systemName: "stop.fill")
                Text("Stop Session")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.red)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    // MARK: - Helper Methods

    private func phaseStatusColor(for index: Int) -> Color {
        if index < adaptiveService.currentPhaseIndex {
            return .green
        } else if index == adaptiveService.currentPhaseIndex {
            return .purple
        } else {
            return Color(.tertiarySystemFill)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func soundsDescription(for phase: AdaptivePhase) -> String {
        let soundNames = phase.sounds.keys.map { id in
            id.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return soundNames.joined(separator: ", ")
    }
}

#Preview {
    let audioEngine = AudioEngine()
    let service = AdaptiveSessionService(audioEngine: audioEngine)
    service.start(mode: .sleepCycle)

    return ActiveAdaptiveSessionView()
        .environment(service)
        .padding()
        .preferredColorScheme(.dark)
}
