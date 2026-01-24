import Foundation
import CoreMotion
import SwiftUI

@Observable
@MainActor
final class MotionService {
    // MARK: - Motion Values (normalized -1 to 1)

    /// Device roll (left/right tilt), normalized to -1...1
    private(set) var roll: Double = 0.0

    /// Device pitch (forward/back tilt), normalized to -1...1
    private(set) var pitch: Double = 0.0

    /// Whether motion hardware is available on this device
    private(set) var isMotionAvailable: Bool = false

    /// Whether motion updates are currently active
    private(set) var isUpdating: Bool = false

    // MARK: - Private Properties

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 30.0 // 30Hz for battery efficiency
    private let smoothingFactor: Double = 0.15 // Low-pass filter for smooth movement

    // MARK: - Initialization

    init() {
        checkMotionAvailability()
    }

    deinit {
        // Ensure cleanup on deinit
        motionManager.stopDeviceMotionUpdates()
    }

    // MARK: - Public Methods

    /// Start receiving motion updates
    func startUpdates() {
        guard isMotionAvailable, !isUpdating else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }

            Task { @MainActor in
                self.processMotion(motion)
            }
        }

        isUpdating = true
    }

    /// Stop receiving motion updates
    func stopUpdates() {
        guard isUpdating else { return }

        motionManager.stopDeviceMotionUpdates()
        isUpdating = false

        // Smoothly reset to center
        withAnimation(.easeOut(duration: 0.3)) {
            roll = 0.0
            pitch = 0.0
        }
    }

    // MARK: - Private Methods

    private func checkMotionAvailability() {
        isMotionAvailable = motionManager.isDeviceMotionAvailable
    }

    private func processMotion(_ motion: CMDeviceMotion) {
        // Get attitude (device orientation)
        let attitude = motion.attitude

        // Normalize roll and pitch to -1...1 range
        // Roll: -pi to pi (full rotation) -> clamp to usable range
        // Pitch: -pi/2 to pi/2 (tilt forward/back)
        let normalizedRoll = clamp(attitude.roll / (.pi / 4), min: -1.0, max: 1.0)
        let normalizedPitch = clamp(attitude.pitch / (.pi / 4), min: -1.0, max: 1.0)

        // Apply low-pass filter for smooth animation
        let smoothedRoll = roll + (normalizedRoll - roll) * smoothingFactor
        let smoothedPitch = pitch + (normalizedPitch - pitch) * smoothingFactor

        // Update values (no animation needed - updates are frequent enough)
        roll = smoothedRoll
        pitch = smoothedPitch
    }

    private func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(Swift.max(value, min), max)
    }
}

// MARK: - Preview Helper

extension MotionService {
    /// Create a service with static values for previews
    static func preview(roll: Double = 0.0, pitch: Double = 0.0) -> MotionService {
        let service = MotionService()
        // Note: In preview, motion won't be available on simulator
        return service
    }
}
