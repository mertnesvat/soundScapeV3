import SwiftUI

/// Animated wave layer using Canvas for smooth 60fps performance
struct WaveLayer: View {
    let color: Color
    let intensity: Float
    let phaseOffset: Double

    @State private var phase: Double = 0

    private var amplitude: CGFloat {
        CGFloat(intensity) * 30
    }

    private var frequency: CGFloat {
        2.5
    }

    private var speed: Double {
        Double(intensity) * 0.5 + 0.3
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let animatedPhase = time * speed + phaseOffset

                // Draw multiple wave layers for depth
                for layerIndex in 0..<3 {
                    let layerOpacity = 0.3 - Double(layerIndex) * 0.08
                    let layerPhaseShift = Double(layerIndex) * 0.3
                    let layerAmplitude = amplitude * (1.0 - CGFloat(layerIndex) * 0.2)

                    let path = createWavePath(
                        size: size,
                        phase: animatedPhase + layerPhaseShift,
                        amplitude: layerAmplitude,
                        frequency: frequency
                    )

                    context.opacity = layerOpacity * Double(intensity)
                    context.fill(
                        path,
                        with: .linearGradient(
                            Gradient(colors: [
                                color.opacity(0.8),
                                color.opacity(0.3)
                            ]),
                            startPoint: CGPoint(x: size.width / 2, y: 0),
                            endPoint: CGPoint(x: size.width / 2, y: size.height)
                        )
                    )
                }
            }
        }
    }

    private func createWavePath(
        size: CGSize,
        phase: Double,
        amplitude: CGFloat,
        frequency: CGFloat
    ) -> Path {
        var path = Path()

        let midY = size.height * 0.6
        let steps = Int(size.width / 2)

        path.move(to: CGPoint(x: 0, y: size.height))

        for step in 0...steps {
            let x = CGFloat(step) * 2
            let relativeX = x / size.width
            let sine = sin(relativeX * .pi * 2 * frequency + phase)
            let y = midY + sine * amplitude

            if step == 0 {
                path.addLine(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        path.addLine(to: CGPoint(x: size.width, y: size.height))
        path.closeSubpath()

        return path
    }
}

/// Droplet ripple effect for rain sounds
struct RippleLayer: View {
    let color: Color
    let intensity: Float

    @State private var ripples: [Ripple] = []
    @State private var lastSpawnTime: Date = .now

    struct Ripple: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var radius: CGFloat = 0
        var opacity: Double = 0.6
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            Canvas { context, size in
                // Spawn new ripples periodically
                let now = timeline.date
                let elapsed = now.timeIntervalSince(lastSpawnTime)
                let spawnRate = 0.3 / Double(intensity + 0.1)

                if elapsed > spawnRate && ripples.count < 10 {
                    Task { @MainActor in
                        spawnRipple(in: size)
                    }
                }

                // Update and draw ripples
                for ripple in ripples {
                    let path = Path(ellipseIn: CGRect(
                        x: ripple.x - ripple.radius,
                        y: ripple.y - ripple.radius,
                        width: ripple.radius * 2,
                        height: ripple.radius * 2
                    ))

                    context.opacity = ripple.opacity
                    context.stroke(
                        path,
                        with: .color(color),
                        lineWidth: 2
                    )
                }
            }
        }
        .onAppear {
            startRippleAnimation()
        }
    }

    private func spawnRipple(in size: CGSize) {
        let newRipple = Ripple(
            x: CGFloat.random(in: 20...(size.width - 20)),
            y: CGFloat.random(in: 20...(size.height * 0.7))
        )
        ripples.append(newRipple)
        lastSpawnTime = .now
    }

    private func startRippleAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            Task { @MainActor in
                updateRipples()
            }
        }
    }

    private func updateRipples() {
        ripples = ripples.compactMap { ripple in
            var updated = ripple
            updated.radius += 2 * CGFloat(intensity + 0.3)
            updated.opacity -= 0.02

            if updated.opacity <= 0 {
                return nil
            }
            return updated
        }
    }
}

#Preview {
    ZStack {
        Color.black

        WaveLayer(color: .blue, intensity: 0.7, phaseOffset: 0)

        WaveLayer(color: .cyan, intensity: 0.5, phaseOffset: 1.5)
            .opacity(0.6)
    }
    .frame(height: 200)
}
