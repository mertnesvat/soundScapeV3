import Foundation

final class SoundEventDetector {

    struct AnalysisResult {
        let events: [SoundEvent]
        let snoreScore: Int
    }

    func analyze(samples: [Float], recordingDuration: TimeInterval, startDate: Date) -> AnalysisResult {
        guard !samples.isEmpty else {
            return AnalysisResult(events: [], snoreScore: 0)
        }

        let sortedSamples = samples.sorted()
        let baseline = sortedSamples[sortedSamples.count / 2] // median

        var events: [SoundEvent] = []
        var i = 0

        while i < samples.count {
            let sample = samples[i]
            let elevation = sample - baseline

            if elevation >= 20 {
                // Loud sound detection
                let event = SoundEvent(
                    timestamp: TimeInterval(i),
                    duration: 1,
                    type: .loudSound,
                    peakDecibels: sample,
                    averageDecibels: sample
                )
                events.append(event)
                i += 1
            } else if elevation >= 8 {
                // Potential snoring or talking - find sustained region
                let regionStart = i
                var regionPeak: Float = sample
                var regionSum: Float = 0
                var regionCount = 0

                while i < samples.count && (samples[i] - baseline) >= 5 {
                    regionSum += samples[i]
                    if samples[i] > regionPeak { regionPeak = samples[i] }
                    regionCount += 1
                    i += 1
                }

                let regionDuration = TimeInterval(regionCount)
                let regionAvg = regionSum / Float(max(1, regionCount))

                if regionDuration >= 3 {
                    // Check for rhythmic pattern (snoring vs talking)
                    let isRhythmic = detectRhythmicPattern(samples: Array(samples[regionStart..<min(regionStart + regionCount, samples.count)]), baseline: baseline)

                    let eventType: SoundEventType
                    if isRhythmic && regionDuration <= 30 {
                        eventType = .snoring
                    } else if regionDuration >= 3 && regionDuration <= 15 && elevation >= 10 {
                        eventType = .talking
                    } else if isRhythmic {
                        eventType = .snoring
                    } else {
                        eventType = .loudSound
                    }

                    let event = SoundEvent(
                        timestamp: TimeInterval(regionStart),
                        duration: regionDuration,
                        type: eventType,
                        peakDecibels: regionPeak,
                        averageDecibels: regionAvg
                    )
                    events.append(event)
                }
            } else {
                i += 1
            }
        }

        // Detect silence periods (5+ minutes below or at baseline)
        events.append(contentsOf: detectSilencePeriods(samples: samples, baseline: baseline))

        // Merge adjacent same-type events within 5 seconds
        events = mergeAdjacentEvents(events)

        // Sort by timestamp
        events.sort { $0.timestamp < $1.timestamp }

        // Calculate snore score
        let snoreScore = calculateSnoreScore(events: events, samples: samples, baseline: baseline, recordingDuration: recordingDuration)

        return AnalysisResult(events: events, snoreScore: snoreScore)
    }

    // MARK: - Rhythmic Pattern Detection

    private func detectRhythmicPattern(samples: [Float], baseline: Float) -> Bool {
        guard samples.count >= 6 else { return false }

        // Look for peaks and valleys alternating
        var peakCount = 0
        var valleyCount = 0
        let threshold = baseline + 3

        for i in 1..<(samples.count - 1) {
            if samples[i] > samples[i - 1] && samples[i] > samples[i + 1] && samples[i] > threshold {
                peakCount += 1
            }
            if samples[i] < samples[i - 1] && samples[i] < samples[i + 1] {
                valleyCount += 1
            }
        }

        // Rhythmic if we see multiple peaks with valleys between them
        return peakCount >= 2 && valleyCount >= 1
    }

    // MARK: - Silence Detection

    private func detectSilencePeriods(samples: [Float], baseline: Float) -> [SoundEvent] {
        var silenceEvents: [SoundEvent] = []
        let minSilenceDuration = 300 // 5 minutes in seconds
        var silenceStart: Int?
        var silenceCount = 0

        for i in 0..<samples.count {
            if samples[i] <= baseline + 2 {
                if silenceStart == nil {
                    silenceStart = i
                }
                silenceCount += 1
            } else {
                if silenceCount >= minSilenceDuration, let start = silenceStart {
                    let event = SoundEvent(
                        timestamp: TimeInterval(start),
                        duration: TimeInterval(silenceCount),
                        type: .silence,
                        peakDecibels: baseline,
                        averageDecibels: baseline
                    )
                    silenceEvents.append(event)
                }
                silenceStart = nil
                silenceCount = 0
            }
        }

        // Handle silence at end of recording
        if silenceCount >= minSilenceDuration, let start = silenceStart {
            let event = SoundEvent(
                timestamp: TimeInterval(start),
                duration: TimeInterval(silenceCount),
                type: .silence,
                peakDecibels: baseline,
                averageDecibels: baseline
            )
            silenceEvents.append(event)
        }

        return silenceEvents
    }

    // MARK: - Event Merging

    private func mergeAdjacentEvents(_ events: [SoundEvent]) -> [SoundEvent] {
        guard !events.isEmpty else { return [] }

        let sorted = events.filter { $0.type != .silence }.sorted { $0.timestamp < $1.timestamp }
        var merged: [SoundEvent] = []

        for event in sorted {
            if let last = merged.last,
               last.type == event.type,
               (event.timestamp - (last.timestamp + last.duration)) <= 5 {
                // Merge
                var combined = last
                let newEnd = max(last.timestamp + last.duration, event.timestamp + event.duration)
                combined = SoundEvent(
                    id: last.id,
                    timestamp: last.timestamp,
                    duration: newEnd - last.timestamp,
                    type: last.type,
                    peakDecibels: max(last.peakDecibels, event.peakDecibels),
                    averageDecibels: (last.averageDecibels + event.averageDecibels) / 2
                )
                merged[merged.count - 1] = combined
            } else {
                merged.append(event)
            }
        }

        // Add back silence events
        merged.append(contentsOf: events.filter { $0.type == .silence })

        return merged
    }

    // MARK: - Snore Score Calculation

    private func calculateSnoreScore(events: [SoundEvent], samples: [Float], baseline: Float, recordingDuration: TimeInterval) -> Int {
        let snoringEvents = events.filter { $0.type == .snoring }
        guard !snoringEvents.isEmpty, recordingDuration > 0 else { return 0 }

        // Percentage of night with snoring (40% weight)
        let totalSnoringDuration = snoringEvents.reduce(0.0) { $0 + $1.duration }
        let snoringPercentage = min(1.0, totalSnoringDuration / recordingDuration)
        let percentageScore = snoringPercentage * 100.0

        // Average intensity above baseline (30% weight)
        let avgIntensity = snoringEvents.reduce(Float(0)) { $0 + ($1.averageDecibels - baseline) } / Float(snoringEvents.count)
        let intensityScore = min(100.0, Double(avgIntensity) * 3.0) // Scale: 33dB above baseline = 100

        // Number of distinct episodes (30% weight)
        let episodeScore = min(100.0, Double(snoringEvents.count) * 5.0) // Scale: 20 episodes = 100

        let rawScore = percentageScore * 0.4 + intensityScore * 0.3 + episodeScore * 0.3
        return max(0, min(100, Int(rawScore)))
    }
}
