import Foundation

// MARK: - Science Content Models

struct ScienceSection: Identifiable {
    let id: String
    let title: String
    let icon: String
    let items: [ScienceItem]
}

struct ScienceItem: Identifiable {
    let id: String
    let title: String
    let icon: String
    let points: [String]
}

// MARK: - Science Content Data

struct SoundScienceContent {

    static let sections: [ScienceSection] = [
        binauralBeatsSection,
        brainwaveStatesSection,
        isochronicTonesSection,
        whiteNoiseSection,
        brownNoiseSection
    ]

    // MARK: - Binaural Beats Overview

    static let binauralBeatsSection = ScienceSection(
        id: "binaural_beats",
        title: String(localized: "Binaural Beats"),
        icon: "headphones",
        items: [
            ScienceItem(
                id: "binaural_what",
                title: String(localized: "What Are Binaural Beats?"),
                icon: "waveform.path",
                points: [
                    String(localized: "Two slightly different frequencies are played, one in each ear"),
                    String(localized: "Your brain perceives the difference between the two frequencies as a rhythmic beat"),
                    String(localized: "For example, 200 Hz in one ear and 210 Hz in the other creates a perceived 10 Hz beat"),
                    String(localized: "This perceived beat can influence your brainwave activity over time")
                ]
            ),
            ScienceItem(
                id: "binaural_headphones",
                title: String(localized: "Why Headphones Are Required"),
                icon: "ear",
                points: [
                    String(localized: "Each ear must receive a different frequency for the effect to work"),
                    String(localized: "Speakers blend the sounds together, eliminating the frequency difference"),
                    String(localized: "Use comfortable, well-fitting headphones or earbuds for the best experience"),
                    String(localized: "Over-ear headphones work well for longer listening sessions")
                ]
            ),
            ScienceItem(
                id: "binaural_entrainment",
                title: String(localized: "How Entrainment Works"),
                icon: "brain.head.profile",
                points: [
                    String(localized: "Your brain naturally synchronizes its electrical activity to rhythmic stimuli"),
                    String(localized: "This process is called frequency-following response or brainwave entrainment"),
                    String(localized: "Over several minutes, your dominant brainwave frequency shifts toward the beat frequency"),
                    String(localized: "Different target frequencies promote different mental states")
                ]
            ),
            ScienceItem(
                id: "binaural_safety",
                title: String(localized: "Safe Listening"),
                icon: "checkmark.shield",
                points: [
                    String(localized: "Keep the volume at a comfortable, moderate level"),
                    String(localized: "Sessions of 15 to 30 minutes are recommended for best results"),
                    String(localized: "Do not use while driving or operating machinery"),
                    String(localized: "If you experience discomfort or dizziness, stop listening and take a break")
                ]
            )
        ]
    )

    // MARK: - Brainwave States

    static let brainwaveStatesSection = ScienceSection(
        id: "brainwave_states",
        title: String(localized: "Brainwave States"),
        icon: "waveform.path.ecg",
        items: [
            ScienceItem(
                id: "wave_delta",
                title: String(localized: "Delta (2 Hz)"),
                icon: "moon.fill",
                points: [
                    String(localized: "The slowest brainwave frequency, associated with deep dreamless sleep"),
                    String(localized: "Promotes physical healing, cell regeneration, and immune system restoration"),
                    String(localized: "Best for deep sleep and physical recovery"),
                    String(localized: "Naturally dominant during stages 3 and 4 of the sleep cycle")
                ]
            ),
            ScienceItem(
                id: "wave_theta",
                title: String(localized: "Theta (6 Hz)"),
                icon: "sparkles",
                points: [
                    String(localized: "Present during light sleep, deep meditation, and creative states"),
                    String(localized: "Associated with vivid imagery, intuition, and subconscious processing"),
                    String(localized: "Best for meditation, creative work, and falling asleep"),
                    String(localized: "Often experienced during the transition between wakefulness and sleep")
                ]
            ),
            ScienceItem(
                id: "wave_alpha",
                title: String(localized: "Alpha (10 Hz)"),
                icon: "leaf.fill",
                points: [
                    String(localized: "The bridge between conscious thinking and the subconscious mind"),
                    String(localized: "Promotes relaxed focus, calm alertness, and reduced anxiety"),
                    String(localized: "Best for studying, light focus, and stress relief"),
                    String(localized: "Naturally present when you close your eyes and relax")
                ]
            ),
            ScienceItem(
                id: "wave_beta",
                title: String(localized: "Beta (20 Hz)"),
                icon: "bolt.fill",
                points: [
                    String(localized: "The dominant frequency during active waking consciousness"),
                    String(localized: "Associated with active concentration, logical thinking, and problem solving"),
                    String(localized: "Best for work sessions and tasks requiring sustained focus"),
                    String(localized: "Higher beta ranges can increase alertness but may also raise stress levels")
                ]
            ),
            ScienceItem(
                id: "wave_gamma",
                title: String(localized: "Gamma (40 Hz)"),
                icon: "star.fill",
                points: [
                    String(localized: "The fastest brainwave frequency, linked to peak cognitive performance"),
                    String(localized: "Associated with heightened perception, memory consolidation, and learning"),
                    String(localized: "Best for complex thinking, information processing, and memory tasks"),
                    String(localized: "Research suggests gamma waves play a role in binding sensory inputs into unified perception")
                ]
            )
        ]
    )

    // MARK: - Isochronic Tones

    static let isochronicTonesSection = ScienceSection(
        id: "isochronic_tones",
        title: String(localized: "Isochronic Tones"),
        icon: "waveform",
        items: [
            ScienceItem(
                id: "iso_what",
                title: String(localized: "What Are Isochronic Tones?"),
                icon: "waveform.path",
                points: [
                    String(localized: "Evenly spaced, rhythmic pulses of a single tone that turn on and off at a set rate"),
                    String(localized: "The sharp on-off pattern creates a distinct beat that the brain can follow"),
                    String(localized: "Each pulse ramps up quickly and drops off sharply, creating clear contrast"),
                    String(localized: "Used for brainwave entrainment similar to binaural beats")
                ]
            ),
            ScienceItem(
                id: "iso_difference",
                title: String(localized: "Key Difference from Binaural Beats"),
                icon: "speaker.wave.2",
                points: [
                    String(localized: "Isochronic tones do not require headphones since only one frequency is used"),
                    String(localized: "The entrainment effect comes from the rhythmic pulsing, not from frequency differences between ears"),
                    String(localized: "They can be played through speakers and still be effective"),
                    String(localized: "Some people find the pulsing sound more noticeable than binaural beats")
                ]
            ),
            ScienceItem(
                id: "iso_when",
                title: String(localized: "When to Use Each"),
                icon: "arrow.left.arrow.right",
                points: [
                    String(localized: "Choose binaural beats for deeper entrainment when you have headphones available"),
                    String(localized: "Choose isochronic tones when you prefer speaker playback or do not have headphones"),
                    String(localized: "Binaural beats are often preferred for sleep and deep meditation sessions"),
                    String(localized: "Isochronic tones can be more effective for focus and alertness states")
                ]
            ),
            ScienceItem(
                id: "iso_how",
                title: String(localized: "How They Work"),
                icon: "gearshape",
                points: [
                    String(localized: "The brain responds to repetitive auditory stimuli by matching its own electrical rhythms"),
                    String(localized: "Sharp, distinct pulses are easier for the brain to follow than subtle frequency differences"),
                    String(localized: "The entrainment effect can be felt within a few minutes of listening"),
                    String(localized: "Consistent use may improve the brain's responsiveness to entrainment over time")
                ]
            )
        ]
    )

    // MARK: - White Noise

    static let whiteNoiseSection = ScienceSection(
        id: "white_noise",
        title: String(localized: "White Noise"),
        icon: "antenna.radiowaves.left.and.right",
        items: [
            ScienceItem(
                id: "white_what",
                title: String(localized: "What Is White Noise?"),
                icon: "waveform.path",
                points: [
                    String(localized: "A consistent sound that contains equal energy across all audible frequencies"),
                    String(localized: "Sounds similar to TV static, a fan running, or rushing air"),
                    String(localized: "Called white noise by analogy with white light, which contains all visible wavelengths"),
                    String(localized: "Creates a constant, uniform acoustic backdrop")
                ]
            ),
            ScienceItem(
                id: "white_sleep",
                title: String(localized: "Sleep Benefits"),
                icon: "bed.double.fill",
                points: [
                    String(localized: "Masks sudden environmental sounds like traffic, voices, and doors closing"),
                    String(localized: "Creates a consistent sound environment that reduces the brain's response to disturbances"),
                    String(localized: "Studies show it can help people fall asleep faster and experience fewer awakenings"),
                    String(localized: "Particularly helpful in noisy environments or for light sleepers")
                ]
            ),
            ScienceItem(
                id: "white_focus",
                title: String(localized: "Focus Benefits"),
                icon: "eye",
                points: [
                    String(localized: "Reduces the distraction caused by unpredictable background sounds"),
                    String(localized: "Provides a steady auditory texture that helps the brain tune out interruptions"),
                    String(localized: "Can improve concentration in open offices and shared workspaces"),
                    String(localized: "Some research suggests it helps with sustained attention tasks")
                ]
            ),
            ScienceItem(
                id: "white_research",
                title: String(localized: "Research Highlights"),
                icon: "book.fill",
                points: [
                    String(localized: "Multiple studies demonstrate improved sleep onset and sleep quality with white noise"),
                    String(localized: "Hospital studies show patients in noisy wards sleep better with white noise machines"),
                    String(localized: "Research indicates white noise can improve memory performance in some individuals"),
                    String(localized: "Effects may vary between individuals, so experimenting with different sounds is recommended")
                ]
            ),
            ScienceItem(
                id: "white_safety",
                title: String(localized: "Safe Listening"),
                icon: "checkmark.shield",
                points: [
                    String(localized: "Keep the volume at or below conversational level for overnight use"),
                    String(localized: "The sound should mask disturbances without being loud enough to cause hearing strain"),
                    String(localized: "Consider using a sleep timer to stop playback after you fall asleep"),
                    String(localized: "Place speakers at a distance rather than using earbuds for all-night listening")
                ]
            )
        ]
    )

    // MARK: - Brown Noise

    static let brownNoiseSection = ScienceSection(
        id: "brown_noise",
        title: String(localized: "Brown Noise"),
        icon: "cloud.fill",
        items: [
            ScienceItem(
                id: "brown_what",
                title: String(localized: "What Makes It Different"),
                icon: "waveform.path",
                points: [
                    String(localized: "Brown noise has more energy in the lower frequencies, creating a deeper, richer sound"),
                    String(localized: "Named after Robert Brown and Brownian motion, not the color brown"),
                    String(localized: "Sounds like a strong waterfall, distant thunder, or heavy wind"),
                    String(localized: "The power decreases as frequency increases, making it warmer and less hissy than white noise")
                ]
            ),
            ScienceItem(
                id: "brown_preference",
                title: String(localized: "Why Some Prefer It"),
                icon: "heart.fill",
                points: [
                    String(localized: "The deep, rumbling quality feels warmer and more natural than white noise"),
                    String(localized: "Less high-frequency content means it is less harsh on the ears over long sessions"),
                    String(localized: "Many people describe it as more soothing and less intrusive"),
                    String(localized: "The low-frequency emphasis can feel enveloping and grounding")
                ]
            ),
            ScienceItem(
                id: "brown_benefits",
                title: String(localized: "Sleep and Relaxation Benefits"),
                icon: "moon.zzz.fill",
                points: [
                    String(localized: "The low frequencies are particularly calming to the nervous system"),
                    String(localized: "Effective at masking low-frequency disturbances like HVAC systems and traffic rumble"),
                    String(localized: "Some users report it helps quiet racing thoughts before sleep"),
                    String(localized: "The steady, deep sound can promote a sense of safety and enclosure")
                ]
            ),
            ScienceItem(
                id: "brown_app_options",
                title: String(localized: "The App's Brown Noise Options"),
                icon: "slider.horizontal.3",
                points: [
                    String(localized: "Brown Noise provides a balanced low-frequency emphasis suitable for most listeners"),
                    String(localized: "Deep Brown Noise offers extra bass emphasis for those who prefer an even deeper sound"),
                    String(localized: "Both options can be mixed with other sounds to create a custom soundscape"),
                    String(localized: "Try combining brown noise with nature sounds for a rich ambient environment")
                ]
            )
        ]
    )
}
