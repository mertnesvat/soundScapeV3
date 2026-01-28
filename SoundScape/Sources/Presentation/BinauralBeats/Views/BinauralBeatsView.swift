import SwiftUI

struct BinauralBeatsView: View {
    @Environment(BinauralBeatEngine.self) private var beatEngine

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Headphone notice for binaural mode
                    if beatEngine.toneType == .binaural {
                        HeadphoneNoticeView()
                    }

                    // Brainwave state selector
                    BrainwaveStateSelectorView()

                    // Tone type picker
                    ToneTypePickerView()

                    // Base frequency selector
                    BaseFrequencySelectorView()

                    // Volume slider
                    BinauralVolumeSliderView()

                    // Play/Stop button
                    BinauralPlayButton()

                    Spacer(minLength: 100)
                }
                .padding()
            }
            .navigationTitle("Binaural Beats")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Headphone Notice

struct HeadphoneNoticeView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "headphones")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Headphones Recommended")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Binaural beats require stereo headphones to work effectively.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Brainwave State Selector

struct BrainwaveStateSelectorView: View {
    @Environment(BinauralBeatEngine.self) private var beatEngine
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(PaywallService.self) private var paywallService

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Brainwave State")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(BrainwaveState.allCases) { state in
                    let isLocked = premiumManager.isPremiumRequired(for: .binauralBeat(state: state))
                    BrainwaveStateCard(
                        state: state,
                        isSelected: beatEngine.brainwaveState == state,
                        isLocked: isLocked
                    ) {
                        if isLocked {
                            paywallService.triggerPaywall(placement: "campaign_trigger") {
                                @Bindable var engine = beatEngine
                                engine.brainwaveState = state
                                beatEngine.updateSettings()
                            }
                        } else {
                            @Bindable var engine = beatEngine
                            engine.brainwaveState = state
                            beatEngine.updateSettings()
                        }
                    }
                }
            }
        }
    }
}

struct BrainwaveStateCard: View {
    let state: BrainwaveState
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    private var stateColor: Color {
        switch state.colorName {
        case "indigo": return .indigo
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .gray
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Image(systemName: state.icon)
                        .font(.title)
                        .foregroundStyle(isSelected ? .white : stateColor)

                    // Lock icon overlay for premium states
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Circle().fill(.black.opacity(0.6)))
                            .offset(x: 16, y: -12)
                    }
                }

                VStack(spacing: 2) {
                    Text(state.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(state.description)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)

                    Text("\(Int(state.frequency)) Hz")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : stateColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? stateColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? stateColor : .clear, lineWidth: 2)
            )
            .opacity(isLocked ? 0.7 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tone Type Picker

struct ToneTypePickerView: View {
    @Environment(BinauralBeatEngine.self) private var beatEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tone Type")
                .font(.headline)

            @Bindable var engine = beatEngine

            Picker("Tone Type", selection: $engine.toneType) {
                ForEach(ToneType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: beatEngine.toneType) { _, _ in
                beatEngine.updateSettings()
            }

            Text(beatEngine.toneType.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Base Frequency Selector

struct BaseFrequencySelectorView: View {
    @Environment(BinauralBeatEngine.self) private var beatEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Base Frequency")
                    .font(.headline)

                Spacer()

                Text(beatEngine.baseFrequency.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            @Bindable var engine = beatEngine

            Picker("Base Frequency", selection: $engine.baseFrequency) {
                ForEach(BaseFrequency.allCases) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: beatEngine.baseFrequency) { _, _ in
                beatEngine.updateSettings()
            }

            Text("Higher frequencies produce brighter tones")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Volume Slider

struct BinauralVolumeSliderView: View {
    @Environment(BinauralBeatEngine.self) private var beatEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Volume")
                    .font(.headline)

                Spacer()

                Text("\(Int(beatEngine.volume * 100))%")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            @Bindable var engine = beatEngine

            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .foregroundStyle(.secondary)

                Slider(value: $engine.volume, in: 0...1, step: 0.05)
                    .tint(.purple)

                Image(systemName: "speaker.wave.3.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Play Button

struct BinauralPlayButton: View {
    @Environment(BinauralBeatEngine.self) private var beatEngine

    private var buttonColor: Color {
        switch beatEngine.brainwaveState.colorName {
        case "indigo": return .indigo
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .purple
        }
    }

    var body: some View {
        Button {
            beatEngine.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: beatEngine.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title2)

                Text(beatEngine.isPlaying ? "Stop" : "Play")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(beatEngine.isPlaying ? Color.red : buttonColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

// MARK: - Preview

#Preview {
    let paywallService = PaywallService()
    BinauralBeatsView()
        .environment(BinauralBeatEngine())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}
