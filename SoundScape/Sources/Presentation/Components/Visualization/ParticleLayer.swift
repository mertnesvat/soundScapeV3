import SwiftUI

/// Particle system layer for fire and nature visualizations
struct ParticleLayer: View {
    let color: Color
    let intensity: Float
    let direction: ParticleDirection
    let particleCount: Int

    @State private var particles: [Particle] = []
    @State private var isInitialized = false

    enum ParticleDirection {
        case up      // Fire - rising embers
        case drift   // Nature - floating leaves
        case down    // Rain droplets
    }

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: CGFloat
        var wobble: CGFloat // Horizontal drift
        var phase: Double   // For sine wave motion
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                if !isInitialized {
                    Task { @MainActor in
                        initializeParticles(in: size)
                    }
                }

                let time = timeline.date.timeIntervalSinceReferenceDate

                for particle in particles {
                    drawParticle(particle, in: context, at: time)
                }
            }
        }
        .onChange(of: intensity) { _, _ in
            // Reinitialize when intensity changes significantly
        }
    }

    private func initializeParticles(in size: CGSize) {
        guard !isInitialized else { return }
        isInitialized = true

        particles = (0..<particleCount).map { _ in
            createParticle(in: size, randomY: true)
        }

        startParticleAnimation(in: size)
    }

    private func createParticle(in size: CGSize, randomY: Bool) -> Particle {
        let baseY: CGFloat
        switch direction {
        case .up:
            baseY = randomY ? CGFloat.random(in: 0...size.height) : size.height + 10
        case .drift:
            baseY = randomY ? CGFloat.random(in: 0...size.height) : CGFloat.random(in: 0...size.height * 0.3)
        case .down:
            baseY = randomY ? CGFloat.random(in: 0...size.height) : -10
        }

        return Particle(
            x: CGFloat.random(in: 0...size.width),
            y: baseY,
            size: CGFloat.random(in: 2...6) * CGFloat(intensity + 0.3),
            opacity: Double.random(in: 0.3...0.8) * Double(intensity),
            speed: CGFloat.random(in: 0.5...2.0) * CGFloat(intensity + 0.3),
            wobble: CGFloat.random(in: -1...1),
            phase: Double.random(in: 0...(.pi * 2))
        )
    }

    private func drawParticle(_ particle: Particle, in context: GraphicsContext, at time: Double) {
        let wobbleOffset = sin(time * 2 + particle.phase) * particle.wobble * 10

        var particleContext = context
        particleContext.opacity = particle.opacity

        switch direction {
        case .up:
            // Fire ember - glowing circle with blur
            let gradient = Gradient(colors: [
                color,
                color.opacity(0.5),
                color.opacity(0)
            ])

            let rect = CGRect(
                x: particle.x + wobbleOffset - particle.size,
                y: particle.y - particle.size,
                width: particle.size * 2,
                height: particle.size * 2
            )

            particleContext.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    gradient,
                    center: CGPoint(x: rect.midX, y: rect.midY),
                    startRadius: 0,
                    endRadius: particle.size
                )
            )

        case .drift:
            // Leaf - small ellipse
            let rect = CGRect(
                x: particle.x + wobbleOffset - particle.size * 0.5,
                y: particle.y - particle.size * 0.3,
                width: particle.size,
                height: particle.size * 0.6
            )

            particleContext.fill(
                Path(ellipseIn: rect),
                with: .color(color.opacity(0.7))
            )

        case .down:
            // Rain drop - elongated
            let rect = CGRect(
                x: particle.x - particle.size * 0.3,
                y: particle.y - particle.size,
                width: particle.size * 0.6,
                height: particle.size * 2
            )

            particleContext.fill(
                Path(ellipseIn: rect),
                with: .color(color.opacity(0.6))
            )
        }
    }

    private func startParticleAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                updateParticles(in: size)
            }
        }
    }

    private func updateParticles(in size: CGSize) {
        particles = particles.map { particle in
            var updated = particle

            switch direction {
            case .up:
                updated.y -= particle.speed * 2
                updated.opacity -= 0.003

                // Reset when out of bounds or faded
                if updated.y < -20 || updated.opacity <= 0 {
                    return createParticle(in: size, randomY: false)
                }

            case .drift:
                updated.y += particle.speed * 0.5
                updated.x += particle.wobble * 0.5

                // Reset when out of bounds
                if updated.y > size.height + 20 || updated.x < -20 || updated.x > size.width + 20 {
                    var newParticle = createParticle(in: size, randomY: false)
                    newParticle.y = -10
                    return newParticle
                }

            case .down:
                updated.y += particle.speed * 3

                if updated.y > size.height + 20 {
                    return createParticle(in: size, randomY: false)
                }
            }

            return updated
        }
    }
}

/// Static grain effect for noise sounds
struct GrainLayer: View {
    let color: Color
    let intensity: Float

    @State private var noiseOffset: CGFloat = 0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let seed = Int(time * 10) % 1000

                // Draw noise grain pattern
                let grainCount = Int(50 * intensity)
                let random = SeededRandom(seed: seed)

                for _ in 0..<grainCount {
                    let x = random.next() * size.width
                    let y = random.next() * size.height
                    let grainSize = CGFloat.random(in: 1...3)
                    let opacity = Double.random(in: 0.1...0.3) * Double(intensity)

                    let rect = CGRect(x: x, y: y, width: grainSize, height: grainSize)
                    context.opacity = opacity
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}

/// Simple seeded random for consistent noise patterns
private class SeededRandom {
    private var seed: Int

    init(seed: Int) {
        self.seed = seed
    }

    func next() -> CGFloat {
        seed = (seed &* 1103515245 &+ 12345) & 0x7fffffff
        return CGFloat(seed) / CGFloat(0x7fffffff)
    }
}

/// Horizontal flow lines for wind visualization
struct FlowLayer: View {
    let color: Color
    let intensity: Float

    @State private var lines: [FlowLine] = []
    @State private var isInitialized = false

    struct FlowLine: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var length: CGFloat
        var speed: CGFloat
        var opacity: Double
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { _ in
            Canvas { context, size in
                if !isInitialized {
                    Task { @MainActor in
                        initializeLines(in: size)
                    }
                }

                for line in lines {
                    var lineContext = context
                    lineContext.opacity = line.opacity

                    let path = Path { p in
                        p.move(to: CGPoint(x: line.x, y: line.y))
                        p.addLine(to: CGPoint(x: line.x + line.length, y: line.y))
                    }

                    lineContext.stroke(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                color.opacity(0),
                                color,
                                color.opacity(0)
                            ]),
                            startPoint: CGPoint(x: line.x, y: line.y),
                            endPoint: CGPoint(x: line.x + line.length, y: line.y)
                        ),
                        lineWidth: 2
                    )
                }
            }
        }
    }

    private func initializeLines(in size: CGSize) {
        guard !isInitialized else { return }
        isInitialized = true

        let lineCount = Int(15 * intensity) + 5
        lines = (0..<lineCount).map { _ in
            createLine(in: size, randomX: true)
        }

        startLineAnimation(in: size)
    }

    private func createLine(in size: CGSize, randomX: Bool) -> FlowLine {
        FlowLine(
            x: randomX ? CGFloat.random(in: -100...size.width) : -100,
            y: CGFloat.random(in: 0...size.height),
            length: CGFloat.random(in: 30...80) * CGFloat(intensity + 0.3),
            speed: CGFloat.random(in: 2...5) * CGFloat(intensity + 0.3),
            opacity: Double.random(in: 0.2...0.5) * Double(intensity)
        )
    }

    private func startLineAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                updateLines(in: size)
            }
        }
    }

    private func updateLines(in size: CGSize) {
        lines = lines.map { line in
            var updated = line
            updated.x += line.speed

            if updated.x > size.width + 50 {
                return createLine(in: size, randomX: false)
            }

            return updated
        }
    }
}

/// Pulsing circle effect for music
struct MelodyLayer: View {
    let color: Color
    let intensity: Float

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                // Draw multiple pulsing rings
                for i in 0..<4 {
                    let phaseOffset = Double(i) * 0.5
                    let pulse = (sin(time * 2 + phaseOffset) + 1) / 2
                    let radius = 20 + pulse * 60 * Double(intensity)
                    let opacity = (1 - pulse) * 0.4 * Double(intensity)

                    let rect = CGRect(
                        x: center.x - radius,
                        y: center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )

                    context.opacity = opacity
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(color),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black

        ParticleLayer(
            color: .orange,
            intensity: 0.8,
            direction: .up,
            particleCount: 30
        )
    }
    .frame(height: 200)
}
