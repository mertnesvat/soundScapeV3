import Foundation

final class SoundEventDetector: Sendable {

    struct AnalysisResult {
        let events: [SoundEvent]
        let snoreScore: Int
    }

    func analyze(
        samples: [Float],
        recordingDuration: TimeInterval,
        startDate: Date
    ) -> AnalysisResult {
        guard samples.count >= 10 else {
            return AnalysisResult(events: [], snoreScore: 0)
        }

        let sortedSamples = samples.sorted()
        let baseline = sortedSamples[sortedSamples.count / 2]

        var events: [SoundEvent] = []
        var i = 0

        while i < samples.count {
            let sample = samples[i]
            let elevation = sample - baseline

            if elevation >= 20 {
                // Loud sound: single spike or short burst
                let startIndex = i
                var peakDB: Float = sample
                while i < samples.count && (samples[i] - baseline) >= 15 && (i - startIndex) < 3 {
                    peakDB = max(peakDB, samples[i])
                    i += 1
                }
                let duration = max(1, Double(i - startIndex))
                let avg = samples[startIndex..<i].reduce(0, +) / Float(i - startIndex)
                events.append(SoundEvent(
                    timestamp: Double(startIndex),
                    duration: duration,
                    type: .loudSound,
                    peakDecibels: peakDB,
                    averageDecibels: avg
                ))
            } else if elevation >= 8 {
                // Possible snoring or talking: sustained elevated sound
                let startIndex = i
                var peakDB: Float = sample
                var sum: Float = 0
                var count = 0
                while i < samples.count && (samples[i] - baseline) >= 5 {
                    peakDB = max(peakDB, samples[i])
                    sum += samples[i]
                    count += 1
                    i += 1
                }
                let duration = Double(i - startIndex)
                let avg = count > 0 ? sum / Float(count) : sample

                if duration >= 3 {
                    // Check for rhythmic pattern (snoring) vs talking
                    let isRhythmic = detectRhythmicPattern(samples: Array(samples[startIndex..<i]), baseline: baseline)

                    if isRhythmic && duration <= 30 {
                        events.append(SoundEvent(
                            timestamp: Double(startIndex),
                            duration: duration,
                            type: .snoring,
                            peakDecibels: peakDB,
                            averageDecibels: avg
                        ))
                    } else if duration <= 15 && elevation >= 10 {
                        events.append(SoundEvent(
                            timestamp: Double(startIndex),
                            duration: duration,
                            type: .talking,
                            peakDecibels: peakDB,
                            averageDecibels: avg
                        ))
                    } else if duration > 15 {
                        events.append(SoundEvent(
                            timestamp: Double(startIndex),
                            duration: duration,
                            type: .snoring,
                            peakDecibels: peakDB,
                            averageDecibels: avg
                        ))
                    }
                }
            } else {
                i += 1
            }
        }

        // Detect silence periods (5+ minutes below baseline + 2dB)
        var silenceStart: Int?
        for j in 0..<samples.count {
            if samples[j] <= baseline + 2 {
                if silenceStart == nil { silenceStart = j }
            } else {
                if let start = silenceStart {
                    let duration = Double(j - start)
                    if duration >= 300 { // 5 minutes
                        events.append(SoundEvent(
                            timestamp: Double(start),
                            duration: duration,
                            type: .silence,
                            peakDecibels: baseline + 2,
                            averageDecibels: baseline
                        ))
                    }
                    silenceStart = nil
                }
            }
        }
        // Handle trailing silence
        if let start = silenceStart {
            let duration = Double(samples.count - start)
            if duration >= 300 {
                events.append(SoundEvent(
                    timestamp: Double(start),
                    duration: duration,
                    type: .silence,
                    peakDecibels: baseline + 2,
                    averageDecibels: baseline
                ))
            }
        }

        // Merge adjacent events of same type within 5 seconds
        events.sort { $0.timestamp < $1.timestamp }
        events = mergeAdjacentEvents(events)

        // Calculate snore score
        let snoreScore = calculateSnoreScore(events: events, samples: samples, baseline: baseline, recordingDuration: recordingDuration)

        return AnalysisResult(events: events, snoreScore: snoreScore)
    }

    // MARK: - Rhythmic Pattern Detection

    private func detectRhythmicPattern(samples: [Float], baseline: Float) -> Bool {
        guard samples.count >= 4 else { return true }

        // Look for peaks and valleys alternating (inhale/exhale pattern)
        var peaks = 0
        var valleys = 0
        let threshold = baseline + 3

        for i in 1..<(samples.count - 1) {
            if samples[i] > samples[i-1] && samples[i] > samples[i+1] && samples[i] > threshold {
                peaks += 1
            }
            if samples[i] < samples[i-1] && samples[i] < samples[i+1] {
                valleys += 1
            }
        }

        // Rhythmic if there are multiple peaks with valleys between them
        return peaks >= 2 && valleys >= 1
    }

    // MARK: - Event Merging

    private func mergeAdjacentEvents(_ events: [SoundEvent]) -> [SoundEvent] {
        guard events.count > 1 else { return events }

        var merged: [SoundEvent] = []
        var current = events[0]

        for i in 1..<events.count {
            let next = events[i]
            let gap = next.timestamp - (current.timestamp + current.duration)

            if next.type == current.type && gap <= 5 {
                // Merge: extend current to include next
                let newDuration = (next.timestamp + next.duration) - current.timestamp
                current = SoundEvent(
                    id: current.id,
                    timestamp: current.timestamp,
                    duration: newDuration,
                    type: current.type,
                    peakDecibels: max(current.peakDecibels, next.peakDecibels),
                    averageDecibels: (current.averageDecibels + next.averageDecibels) / 2
                )
            } else {
                merged.append(current)
                current = next
            }
        }
        merged.append(current)

        return merged
    }

    // MARK: - Snore Score Calculation

    private func calculateSnoreScore(
        events: [SoundEvent],
        samples: [Float],
        baseline: Float,
        recordingDuration: TimeInterval
    ) -> Int {
        guard recordingDuration > 0 else { return 0 }

        let snoringEvents = events.filter { $0.type == .snoring }
        guard !snoringEvents.isEmpty else { return 0 }

        // 40% weight: percentage of night spent snoring
        let totalSnoringDuration = snoringEvents.reduce(0.0) { $0 + $1.duration }
        let snoringPercentage = totalSnoringDuration / recordingDuration
        let percentageScore = min(1.0, snoringPercentage / 0.3) * 40.0 // 30% snoring = max score

        // 30% weight: average intensity above baseline
        let avgIntensity = snoringEvents.reduce(Float(0)) { $0 + ($1.averageDecibels - baseline) } / Float(snoringEvents.count)
        let intensityScore = min(1.0, Double(avgIntensity) / 20.0) * 30.0 // 20dB above baseline = max

        // 30% weight: number of distinct episodes
        let episodeScore = min(1.0, Double(snoringEvents.count) / 20.0) * 30.0 // 20 episodes = max

        return min(100, max(0, Int(percentageScore + intensityScore + episodeScore)))
    }
}
