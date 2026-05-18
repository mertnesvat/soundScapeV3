import SwiftUI

/// Editorial sleep timer — a saturated yellow color-block hero containing the
/// hero countdown numeral and a peach sparkline footer, with black-outlined
/// preset pill chips below. Replaces the legacy purple progress-ring layout.
struct SleepTimerView: View {
    @Environment(SleepTimerService.self) private var timerService
    @Environment(\.dismiss) private var dismiss

    private let presetColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    private var displayTime: String {
        let seconds = timerService.isActive ? timerService.remainingSeconds : 0
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d", hours, minutes)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    private var activeMinutes: Int? {
        guard timerService.isActive else { return nil }
        return timerService.totalSeconds / 60
    }

    private var sparklineProgress: CGFloat {
        guard timerService.isActive, timerService.totalSeconds > 0 else { return 0 }
        return CGFloat(timerService.progress)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar

                yellowHeroBlock
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                presetChipGrid
                    .padding(.horizontal, 24)
                    .padding(.top, 28)

                if timerService.isActive {
                    cancelButton
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                } else {
                    fadeFootnote
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Tokens.colorCream.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("SLEEP TIMER")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.4)
                .foregroundColor(Tokens.colorInk.opacity(0.5))
            Spacer(minLength: 0)
            Button {
                dismiss()
            } label: {
                Text("DONE")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(Tokens.colorInk)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Tokens.colorInk, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Done")
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Yellow hero block

    private var yellowHeroBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey("Sleep Timer"))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Tokens.colorInk)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            Text(displayTime)
                .font(.system(size: 96, weight: .black, design: .default))
                .monospacedDigit()
                .foregroundColor(Tokens.colorInk)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 24)
                .padding(.top, 2)
                .padding(.bottom, 12)

            Rectangle()
                .fill(Tokens.colorInk.opacity(0.85))
                .frame(height: 1)
                .padding(.horizontal, 24)

            sparkline
                .frame(height: 36)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Tokens.radiusBlock, style: .continuous)
                .fill(Tokens.colorYellow)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(timerService.isActive
            ? "Sleep timer, \(displayTime) remaining"
            : "Sleep timer"))
    }

    // MARK: - Sparkline footer

    private var sparkline: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let midY = height / 2
            let amplitude: CGFloat = max(4, height / 3)
            let cycles: CGFloat = 6
            let drawnWidth = timerService.isActive
                ? max(0, width * sparklineProgress)
                : width

            ZStack(alignment: .leading) {
                if timerService.isActive {
                    sparklinePath(width: width,
                                  midY: midY,
                                  amplitude: amplitude,
                                  cycles: cycles)
                        .stroke(Tokens.colorPeach.opacity(0.3),
                                style: StrokeStyle(lineWidth: 2,
                                                   lineCap: .round,
                                                   lineJoin: .round))
                }

                sparklinePath(width: drawnWidth,
                              midY: midY,
                              amplitude: amplitude,
                              cycles: cycles)
                    .stroke(Tokens.colorPeach.opacity(timerService.isActive ? 1.0 : 0.55),
                            style: StrokeStyle(lineWidth: 2.5,
                                               lineCap: .round,
                                               lineJoin: .round))
                    .animation(.linear(duration: 1), value: sparklineProgress)
            }
        }
        .accessibilityHidden(true)
    }

    private func sparklinePath(width: CGFloat,
                               midY: CGFloat,
                               amplitude: CGFloat,
                               cycles: CGFloat) -> Path {
        Path { path in
            guard width > 0 else { return }
            let stepCount = 60
            let dx = width / CGFloat(stepCount)
            path.move(to: CGPoint(x: 0, y: midY))
            for step in 1...stepCount {
                let x = CGFloat(step) * dx
                let phase = (CGFloat(step) / CGFloat(stepCount)) * cycles * .pi * 2
                let y = midY - sin(phase) * amplitude
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
    }

    // MARK: - Preset chip grid

    private var presetChipGrid: some View {
        LazyVGrid(columns: presetColumns, spacing: 10) {
            ForEach(SleepTimerPreset.presets) { preset in
                let isActive = activeMinutes == preset.minutes
                Button {
                    if isActive {
                        timerService.cancel()
                    } else {
                        timerService.start(minutes: preset.minutes)
                    }
                } label: {
                    Text(preset.localizedLabel)
                        .font(.system(size: 13, weight: .bold))
                        .tracking(0.6)
                        .foregroundColor(isActive ? .white : Tokens.colorInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .fill(isActive ? Tokens.colorOrange : Tokens.colorCream)
                        )
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(isActive ? Tokens.colorOrange : Tokens.colorInk,
                                        lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(preset.localizedLabel))
                .accessibilityAddTraits(isActive ? [.isSelected] : [])
            }
        }
    }

    // MARK: - Cancel button (active timer only)

    private var cancelButton: some View {
        Button {
            timerService.cancel()
        } label: {
            Text(LocalizedStringKey("Cancel Timer"))
                .font(.system(size: 13, weight: .bold))
                .tracking(1.0)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Tokens.colorInk)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cancel timer")
    }

    // MARK: - Fade footnote (preset state)

    private var fadeFootnote: some View {
        Text(LocalizedStringKey("Audio will gradually fade out during the last 30 seconds"))
            .font(.system(size: 12, weight: .regular))
            .foregroundColor(Tokens.colorInk.opacity(0.6))
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    SleepTimerView()
        .environment(SleepTimerService(audioEngine: AudioEngine()))
}
