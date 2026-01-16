import SwiftUI

struct AdaptiveModeCardView: View {
    let mode: AdaptiveMode
    let onStart: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 16) {
                    // Icon
                    Image(systemName: mode.icon)
                        .font(.title)
                        .foregroundColor(.purple)
                        .frame(width: 50, height: 50)
                        .background(Color.purple.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Text content
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(mode.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal)

                    // Phase preview
                    PhasePreviewView(phases: mode.phases)
                        .padding(.horizontal)

                    // Duration info
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("Total Duration: \(totalDurationFormatted)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)

                    // Start button
                    Button {
                        onStart()
                    } label: {
                        Text("Start Session")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var totalDurationFormatted: String {
        let totalMinutes = mode.phases.reduce(0) { $0 + $1.duration }
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let minutes = totalMinutes % 60
            if minutes == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(minutes)m"
        }
        return "\(totalMinutes)m"
    }
}

#Preview {
    VStack {
        AdaptiveModeCardView(mode: .sleepCycle) {
            print("Start tapped")
        }
        AdaptiveModeCardView(mode: .focusSession) {
            print("Start tapped")
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}
