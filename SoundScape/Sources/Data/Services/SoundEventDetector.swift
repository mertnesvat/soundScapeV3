import Foundation

final class SoundEventDetector: Sendable {

    /// Analyzes decibel samples to detect sound events and calculate a snore score.
    /// - Parameters:
    ///   - samples: Array of decibel readings, one per second
    ///   - recordingDuration: Total recording duration in seconds
    ///   - startDate: When the recording started
    /// - Returns: Detected events and calculated snore score (0-100)
    func analyze(samples: [Float], recordingDuration: TimeInterval, startDate: Date) -> (events: [SoundEvent], snoreScore: Int) {
        guard samples.count >= 10 else {
            return (events: [], snoreScore: 0)
        }

        // Calculate baseline noise floor (median of all samples)
        let sorted = samples.sorted()
        let baseline = sorted[sorted.count / 2]

        var events: [SoundEvent] = []
        var i = 0

        while i < samples.count {
            let db = samples[i]
            let aboveBaseline = db - baseline

            if aboveBaseline >= 20 {
                // Loud sound detection: 20+ dB above baseline, 1-3 seconds
                let start = i
                var peak: Float = db
                while i < samples.count && (samples[i] - baseline) >= 15 && (i - start) < 5 {
                    peak = max(peak, samples[i])
                    i += 1
                }
                let duration = max(1.0, Double(i - start))
                let avg = samples[start..<i].reduce(0, +) / Float(i - start)
                events.append(SoundEvent(
                    timestamp: Double(start),
                    duration: duration,
                    type: .loudSound,
                    peakDecibels: peak,
                    averageDecibels: avg
                ))
            } else if aboveBaseline >= 8 {
                // Potential snoring or talking
                let start = i
                var peak: Float = db
                var dbValues: [Float] = [db]
                while i < samples.count && (samples[i] - baseline) >= 5 {
                    peak = max(peak, samples[i])
                    dbValues.append(samples[i])
                    i += 1
                }
                let duration = Double(i - start)
                let avg = dbValues.reduce(0, +) / Float(dbValues.count)

                if duration >= 3 && duration <= 30 {
                    // Check for rhythmic pattern (snoring tends to oscillate)
                    let isRhythmic = detectRhythmicPattern(dbValues)

                    if isRhythmic {
                        events.append(SoundEvent(
                            timestamp: Double(start),
                            duration: duration,
                            type: .snoring,
                            peakDecibels: peak,
                            averageDecibels: avg
                        ))
                    } else if duration >= 3 && duration <= 15 && aboveBaseline >= 10 {
                        events.append(SoundEvent(
                            timestamp: Double(start),
                            duration: duration,
                            type: .talking,
                            peakDecibels: peak,
                            averageDecibels: avg
                        ))
                    } else if duration >= 3 {
                        // Default to snoring for sustained elevated sound
                        events.append(SoundEvent(
                            timestamp: Double(start),
                            duration: duration,
                            type: .snoring,
                            peakDecibels: peak,
                            averageDecibels: avg
                        ))
                    }
                }
            } else {
                i += 1
            }
        }

        // Detect silence periods (5+ minutes at or below baseline)
        events.append(contentsOf: detectSilencePeriods(samples: samples, baseline: baseline))

        // Merge adjacent events of the same type within 5 seconds
        events = mergeAdjacentEvents(events)

        // Sort by timestamp
        events.sort { $0.timestamp < $1.timestamp }

        // Calculate snore score
        let snoreScore = calculateSnoreScore(events: events, samples: samples, baseline: baseline, totalDuration: recordingDuration)

        return (events: events, snoreScore: snoreScore)
    }

    // MARK: - Private Helpers

    private func detectRhythmicPattern(_ values: [Float]) -> Bool {
        guard values.count >= 4 else { return false }

        // Look for peaks and valleys - snoring has a wave-like pattern
        var peakCount = 0
        for j in 1..<(values.count - 1) {
            if values[j] > values[j - 1] && values[j] > values[j + 1] {
                peakCount += 1
            }
        }

        // Rhythmic if there are multiple peaks relative to duration
        let peaksPerSecond = Float(peakCount) / Float(values.count)
        return peaksPerSecond >= 0.1 && peakCount >= 2
    }

    private func detectSilencePeriods(samples: [Float], baseline: Float) -> [SoundEvent] {
        var silenceEvents: [SoundEvent] = []
        let minSilenceDuration = 300 // 5 minutes in seconds

        var silenceStart: Int?
        for i in 0..<samples.count {
            if samples[i] <= baseline + 2 {
                if silenceStart == nil {
                    silenceStart = i
                }
            } else {
                if let start = silenceStart {
                    let duration = i - start
                    if duration >= minSilenceDuration {
                        let slice = Array(samples[start..<i])
                        let peak = slice.max() ?? 0
                        let avg = slice.reduce(0, +) / Float(slice.count)
                        silenceEvents.append(SoundEvent(
                            timestamp: Double(start),
                            duration: Double(duration),
                            type: .silence,
                            peakDecibels: peak,
                            averageDecibels: avg
                        ))
                    }
                    silenceStart = nil
                }
            }
        }

        // Handle silence at end of recording
        if let start = silenceStart {
            let duration = samples.count - start
            if duration >= minSilenceDuration {
                let slice = Array(samples[start...])
                let peak = slice.max() ?? 0
                let avg = slice.reduce(0, +) / Float(slice.count)
                silenceEvents.append(SoundEvent(
                    timestamp: Double(start),
                    duration: Double(duration),
                    type: .silence,
                    peakDecibels: peak,
                    averageDecibels: avg
                ))
            }
        }

        return silenceEvents
    }

    private func mergeAdjacentEvents(_ events: [SoundEvent]) -> [SoundEvent] {
        let sorted = events.filter { $0.type != .silence }.sorted { $0.timestamp < $1.timestamp }
        var merged: [SoundEvent] = []

        for event in sorted {
            if let last = merged.last,
               last.type == event.type,
               event.timestamp - (last.timestamp + last.duration) <= 5.0 {
                // Merge
                let newDuration = (event.timestamp + event.duration) - last.timestamp
                let newPeak = max(last.peakDecibels, event.peakDecibels)
                let newAvg = (last.averageDecibels + event.averageDecibels) / 2
                merged[merged.count - 1] = SoundEvent(
                    id: last.id,
                    timestamp: last.timestamp,
                    duration: newDuration,
                    type: last.type,
                    peakDecibels: newPeak,
                    averageDecibels: newAvg
                )
            } else {
                merged.append(event)
            }
        }

        // Add back silence events (not merged)
        merged.append(contentsOf: events.filter { $0.type == .silence })

        return merged
    }

    private func calculateSnoreScore(events: [SoundEvent], samples: [Float], baseline: Float, totalDuration: TimeInterval) -> Int {
        let snoringEvents = events.filter { $0.type == .snoring }
        guard !snoringEvents.isEmpty else { return 0 }

        let totalSnoringSeconds = snoringEvents.reduce(0.0) { $0 + $1.duration }

        // 40% weight: Percentage of night with snoring
        let snoringPercentage = min(1.0, totalSnoringSeconds / max(1, totalDuration))
        let percentageScore = snoringPercentage * 40

        // 30% weight: Average snoring intensity above baseline
        let avgIntensity = snoringEvents.reduce(Float(0)) { $0 + ($1.averageDecibels - baseline) } / Float(snoringEvents.count)
        let intensityScore = min(30.0, Double(avgIntensity) / 30.0 * 30)

        // 30% weight: Number of distinct snoring episodes
        let episodeScore = min(30.0, Double(snoringEvents.count) / 20.0 * 30)

        return min(100, max(0, Int(percentageScore + intensityScore + episodeScore)))
    }
}
