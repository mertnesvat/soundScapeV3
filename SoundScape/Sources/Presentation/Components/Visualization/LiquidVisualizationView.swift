import SwiftUI

/// Main visualization canvas that renders layered animations based on active sounds
struct LiquidVisualizationView: View {
    let activeSounds: [ActiveSound]
    let height: CGFloat

    init(activeSounds: [ActiveSound], height: CGFloat = 150) {
        self.activeSounds = activeSounds
        self.height = height
    }

    private var visualizationLayers: [VisualizationLayer] {
        activeSounds.map { VisualizationLayer(from: $0) }
    }

    private var combinedIntensity: Double {
        guard !activeSounds.isEmpty else { return 0 }
        let totalVolume = activeSounds.reduce(0) { $0 + Double($1.volume) }
        return min(totalVolume / Double(activeSounds.count) * 1.2, 1.0)
    }

    var body: some View {
        ZStack {
            // Render each sound's visualization layer
            ForEach(Array(visualizationLayers.enumerated()), id: \.element.id) { index, layer in
                visualizationView(for: layer, index: index)
                    .opacity(Double(layer.intensity) * 0.8)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func visualizationView(for layer: VisualizationLayer, index: Int) -> some View {
        let phaseOffset = Double(index) * 1.2

        switch layer.type {
        case .wave:
            WaveLayer(
                color: layer.color,
                intensity: layer.intensity,
                phaseOffset: phaseOffset
            )

        case .particles:
            if layer.category == .fire {
                ParticleLayer(
                    color: layer.color,
                    intensity: layer.intensity,
                    direction: .up,
                    particleCount: Int(20 * layer.intensity) + 10
                )
            } else {
                // Nature - drifting particles
                ParticleLayer(
                    color: layer.color,
                    intensity: layer.intensity,
                    direction: .drift,
                    particleCount: Int(15 * layer.intensity) + 5
                )
            }

        case .grain:
            GrainLayer(
                color: layer.color,
                intensity: layer.intensity
            )

        case .flow:
            FlowLayer(
                color: layer.color,
                intensity: layer.intensity
            )

        case .melody:
            MelodyLayer(
                color: layer.color,
                intensity: layer.intensity
            )
        }
    }
}

/// Compact mini-visualization for sound cards
struct MiniVisualizationView: View {
    let sound: Sound
    let volume: Float
    let size: CGFloat

    init(sound: Sound, volume: Float = 0.7, size: CGFloat = 40) {
        self.sound = sound
        self.volume = volume
        self.size = size
    }

    private var vizType: VisualizationType {
        VisualizationType.from(sound.category)
    }

    private var color: Color {
        VisualizationType.color(for: sound.category)
    }

    var body: some View {
        ZStack {
            switch vizType {
            case .wave:
                MiniWaveView(color: color, intensity: volume)

            case .particles:
                MiniParticleView(
                    color: color,
                    intensity: volume,
                    isFireStyle: sound.category == .fire
                )

            case .grain:
                MiniGrainView(color: color, intensity: volume)

            case .flow:
                MiniFlowView(color: color, intensity: volume)

            case .melody:
                MiniMelodyView(color: color, intensity: volume)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Mini Visualization Components

private struct MiniWaveView: View {
    let color: Color
    let intensity: Float

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = size.height / 2

                for i in 0..<3 {
                    let phase = CGFloat(time * 2 + Double(i) * 0.5)
                    let amplitude = CGFloat(intensity) * 8 * (1 - CGFloat(i) * 0.2)

                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: center))

                    for x in stride(from: CGFloat(0), through: size.width, by: 2) {
                        let normalizedX = x / size.width
                        let sineValue = sin(normalizedX * CGFloat.pi * 3 + phase)
                        let y = center + sineValue * amplitude
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    context.opacity = 0.5 - Double(i) * 0.1
                    context.stroke(path, with: .color(color), lineWidth: 2)
                }
            }
        }
    }
}

private struct MiniParticleView: View {
    let color: Color
    let intensity: Float
    let isFireStyle: Bool

    @State private var particles: [(x: CGFloat, y: CGFloat, speed: CGFloat)] = []

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { _ in
            Canvas { context, size in
                if particles.isEmpty {
                    Task { @MainActor in
                        initParticles(in: size)
                    }
                }

                for (index, particle) in particles.enumerated() {
                    let rect = CGRect(
                        x: particle.x - 2,
                        y: particle.y - 2,
                        width: 4,
                        height: 4
                    )
                    context.opacity = Double(intensity) * 0.6
                    context.fill(Path(ellipseIn: rect), with: .color(color))

                    // Update position
                    Task { @MainActor in
                        updateParticle(at: index, in: size)
                    }
                }
            }
        }
    }

    private func initParticles(in size: CGSize) {
        particles = (0..<8).map { _ in
            (
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                speed: CGFloat.random(in: 0.5...1.5)
            )
        }
    }

    private func updateParticle(at index: Int, in size: CGSize) {
        guard index < particles.count else { return }
        var p = particles[index]

        if isFireStyle {
            p.y -= p.speed
            if p.y < 0 {
                p.y = size.height
                p.x = CGFloat.random(in: 0...size.width)
            }
        } else {
            p.y += p.speed * 0.5
            p.x += CGFloat.random(in: -0.5...0.5)
            if p.y > size.height {
                p.y = 0
                p.x = CGFloat.random(in: 0...size.width)
            }
        }

        particles[index] = p
    }
}

private struct MiniGrainView: View {
    let color: Color
    let intensity: Float

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
            Canvas { context, size in
                let seed = Int(timeline.date.timeIntervalSinceReferenceDate * 10) % 100

                for i in 0..<Int(15 * intensity) {
                    let x = CGFloat((seed + i * 7) % Int(size.width))
                    let y = CGFloat((seed + i * 13) % Int(size.height))

                    let rect = CGRect(x: x, y: y, width: 2, height: 2)
                    context.opacity = Double.random(in: 0.2...0.4)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}

private struct MiniFlowView: View {
    let color: Color
    let intensity: Float

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                for i in 0..<4 {
                    let baseY = size.height * CGFloat(i + 1) / 5
                    let offset = CGFloat(fmod(time * 20 + Double(i * 10), Double(size.width + 20))) - 10

                    var path = Path()
                    path.move(to: CGPoint(x: offset, y: baseY))
                    path.addLine(to: CGPoint(x: offset + 15, y: baseY))

                    context.opacity = Double(intensity) * 0.5
                    context.stroke(path, with: .color(color), lineWidth: 2)
                }
            }
        }
    }
}

private struct MiniMelodyView: View {
    let color: Color
    let intensity: Float

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let pulse = (sin(time * 3) + 1) / 2

                for i in 0..<2 {
                    let radius = 5 + pulse * 10 + Double(i) * 5
                    let opacity = (1 - pulse * 0.5) * Double(intensity) * 0.5

                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )

                    context.opacity = opacity
                    context.stroke(Path(ellipseIn: rect), with: .color(color), lineWidth: 1.5)
                }
            }
        }
    }
}

#Preview("Full Visualization") {
    let sampleSounds: [ActiveSound] = [
        ActiveSound(
            id: "rain",
            sound: Sound(id: "rain", name: "Rain", category: .weather, fileName: "rain.mp3"),
            volume: 0.7,
            isPlaying: true
        ),
        ActiveSound(
            id: "fire",
            sound: Sound(id: "fire", name: "Fire", category: .fire, fileName: "fire.mp3"),
            volume: 0.5,
            isPlaying: true
        )
    ]

    return VStack {
        LiquidVisualizationView(activeSounds: sampleSounds, height: 150)
            .padding()

        HStack(spacing: 20) {
            ForEach(SoundCategory.allCases, id: \.self) { category in
                MiniVisualizationView(
                    sound: Sound(id: category.rawValue, name: category.rawValue, category: category, fileName: ""),
                    volume: 0.7
                )
            }
        }
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
