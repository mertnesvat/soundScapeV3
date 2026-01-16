import SwiftUI

struct PhasePreviewView: View {
    let phases: [AdaptivePhase]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Phases")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                HStack(spacing: 12) {
                    // Phase number indicator
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 28, height: 28)
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }

                    // Phase info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(phase.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(soundsDescription(for: phase))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Duration
                    Text("\(phase.duration)m")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                if index < phases.count - 1 {
                    // Connector line
                    HStack {
                        Rectangle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 2, height: 12)
                            .padding(.leading, 13)
                        Spacer()
                    }
                }
            }
        }
    }

    private func soundsDescription(for phase: AdaptivePhase) -> String {
        let soundNames = phase.sounds.keys.map { id in
            id.replacingOccurrences(of: "_", with: " ").capitalized
        }
        return soundNames.joined(separator: ", ")
    }
}

#Preview {
    PhasePreviewView(phases: AdaptiveMode.sleepCycle.phases)
        .padding()
        .background(Color(.secondarySystemBackground))
        .preferredColorScheme(.dark)
}
