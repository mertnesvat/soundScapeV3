import Foundation

// MARK: - Science Content Models

struct ScienceSection: Identifiable {
    let id: String
    let title: String
    let icon: String
    let content: [ScienceArticle]
}

struct ScienceArticle: Identifiable {
    let id: String
    let title: String
    let body: String
    let icon: String
    let bulletPoints: [String]
}

// MARK: - Science Content Data Source

struct ScienceContentDataSource {

    static let sections: [ScienceSection] = [
        binauralBeatsSection,
        brainwaveStatesSection,
        isochronicTonesSection,
        whiteNoiseSection,
        brownNoiseSection
    ]

    // MARK: - Binaural Beats

    static let binauralBeatsSection = ScienceSection(
        id: "binaural_beats",
        title: String(localized: "Binaural Beats"),
        icon: "headphones",
        content: [
            ScienceArticle(
                id: "binaural_overview",
                title: String(localized: "What Are Binaural Beats?"),
                body: String(localized: "Binaural beats are an auditory illusion created when two slightly different frequencies are played in each ear. Your brain perceives a third tone — the \"beat\" — at the difference between the two frequencies."),
                icon: "waveform.path",
                bulletPoints: [
                    String(localized: "Two tones with slightly different frequencies are played, one in each ear"),
                    String(localized: "Your brain perceives a rhythmic beat at the frequency difference"),
                    String(localized: "For example: 200 Hz in the left ear and 210 Hz in the right creates a 10 Hz beat"),
                    String(localized: "Stereo headphones are required for the effect to work")
                ]
            ),
            ScienceArticle(
                id: "binaural_how_works",
                title: String(localized: "How Do They Work?"),
                body: String(localized: "Your brain naturally synchronizes its electrical activity to external rhythmic stimuli — a process called \"entrainment.\" Binaural beats encourage your brainwaves to align with the beat frequency, potentially shifting your mental state."),
                icon: "brain.head.profile",
                bulletPoints: [
                    String(localized: "Brainwave entrainment is a well-documented neurological phenomenon"),
                    String(localized: "Regular listening may enhance the entrainment effect over time"),
                    String(localized: "Effects are subtle and work best in a calm, quiet environment"),
                    String(localized: "Best used with eyes closed for deeper relaxation")
                ]
            )
        ]
    )

    // MARK: - Brainwave States

    static let brainwaveStatesSection = ScienceSection(
        id: "brainwave_states",
        title: String(localized: "Brainwave States"),
        icon: "brain",
        content: [
            ScienceArticle(
                id: "delta_waves",
                title: String(localized: "Delta Waves (0.5–4 Hz)"),
                body: String(localized: "Delta waves are the slowest brainwaves, dominant during deep dreamless sleep. They promote physical healing, regeneration, and immune system support."),
                icon: "moon.fill",
                bulletPoints: [
                    String(localized: "Associated with deep, restorative sleep"),
                    String(localized: "Promote physical healing and cell regeneration"),
                    String(localized: "Support immune system function"),
                    String(localized: "Best used at bedtime for deep sleep")
                ]
            ),
            ScienceArticle(
                id: "theta_waves",
                title: String(localized: "Theta Waves (4–8 Hz)"),
                body: String(localized: "Theta waves occur during light sleep, deep meditation, and creative daydreaming. They bridge the conscious and subconscious mind."),
                icon: "sparkles",
                bulletPoints: [
                    String(localized: "Enhanced creativity and intuition"),
                    String(localized: "Deep meditative states and vivid imagery"),
                    String(localized: "Memory consolidation during light sleep"),
                    String(localized: "Best used for meditation and creative work")
                ]
            ),
            ScienceArticle(
                id: "alpha_waves",
                title: String(localized: "Alpha Waves (8–14 Hz)"),
                body: String(localized: "Alpha waves are present during calm, relaxed wakefulness. They represent a state of alert relaxation — the bridge between active thinking and deep rest."),
                icon: "leaf.fill",
                bulletPoints: [
                    String(localized: "Calm, relaxed but alert mental state"),
                    String(localized: "Reduced stress and anxiety"),
                    String(localized: "Improved learning and focus"),
                    String(localized: "Best used for relaxation and light study")
                ]
            ),
            ScienceArticle(
                id: "beta_waves",
                title: String(localized: "Beta Waves (14–30 Hz)"),
                body: String(localized: "Beta waves dominate during active, analytical thinking. Higher beta states support concentration, problem-solving, and alert engagement."),
                icon: "bolt.fill",
                bulletPoints: [
                    String(localized: "Active concentration and problem-solving"),
                    String(localized: "Enhanced analytical thinking"),
                    String(localized: "Increased alertness and focus"),
                    String(localized: "Best used for work, study, and productivity")
                ]
            ),
            ScienceArticle(
                id: "gamma_waves",
                title: String(localized: "Gamma Waves (30–100 Hz)"),
                body: String(localized: "Gamma waves are the fastest brainwaves, associated with peak cognitive performance, heightened perception, and moments of insight."),
                icon: "star.fill",
                bulletPoints: [
                    String(localized: "Peak cognitive performance and insight"),
                    String(localized: "Heightened sensory perception"),
                    String(localized: "Associated with \"flow state\" experiences"),
                    String(localized: "Best used for demanding cognitive tasks")
                ]
            )
        ]
    )

    // MARK: - Isochronic Tones

    static let isochronicTonesSection = ScienceSection(
        id: "isochronic_tones",
        title: String(localized: "Isochronic Tones"),
        icon: "waveform",
        content: [
            ScienceArticle(
                id: "isochronic_overview",
                title: String(localized: "What Are Isochronic Tones?"),
                body: String(localized: "Isochronic tones are evenly spaced pulses of a single tone that turn on and off at a regular rate. Unlike binaural beats, they don't require headphones because the rhythmic pulse is in the audio itself."),
                icon: "waveform.path.ecg",
                bulletPoints: [
                    String(localized: "Single tone pulsing on and off at a precise rhythm"),
                    String(localized: "No headphones required — works through speakers"),
                    String(localized: "Generally considered more stimulating than binaural beats"),
                    String(localized: "Effective for focus and concentration sessions")
                ]
            ),
            ScienceArticle(
                id: "isochronic_vs_binaural",
                title: String(localized: "Isochronic vs. Binaural"),
                body: String(localized: "Both isochronic tones and binaural beats aim to entrain brainwaves, but they work differently. Choose based on your situation and preference."),
                icon: "arrow.left.arrow.right",
                bulletPoints: [
                    String(localized: "Binaural beats require headphones; isochronic tones do not"),
                    String(localized: "Isochronic tones produce a sharper, more pronounced pulse"),
                    String(localized: "Binaural beats create a smoother, more immersive experience"),
                    String(localized: "Try both to discover which works best for you")
                ]
            )
        ]
    )

    // MARK: - White Noise

    static let whiteNoiseSection = ScienceSection(
        id: "white_noise",
        title: String(localized: "White Noise"),
        icon: "speaker.wave.3.fill",
        content: [
            ScienceArticle(
                id: "white_noise_overview",
                title: String(localized: "What Is White Noise?"),
                body: String(localized: "White noise contains all audible frequencies at equal intensity — like a constant, even \"hiss.\" It creates a consistent sonic blanket that masks sudden environmental sounds."),
                icon: "waveform.badge.magnifyingglass",
                bulletPoints: [
                    String(localized: "Equal energy across all audible frequencies"),
                    String(localized: "Masks sudden noises like traffic, snoring, or doors"),
                    String(localized: "Creates a consistent, predictable sound environment"),
                    String(localized: "Named after white light, which contains all colors")
                ]
            ),
            ScienceArticle(
                id: "white_noise_benefits",
                title: String(localized: "Benefits for Sleep & Focus"),
                body: String(localized: "Research supports white noise as an effective tool for improving sleep quality and enhancing concentration, especially in noisy environments."),
                icon: "moon.zzz.fill",
                bulletPoints: [
                    String(localized: "Helps you fall asleep faster by masking disturbances"),
                    String(localized: "Improves sleep continuity through the night"),
                    String(localized: "Enhances focus in open offices and shared spaces"),
                    String(localized: "Keep volume at a comfortable, moderate level for safe listening")
                ]
            )
        ]
    )

    // MARK: - Brown Noise

    static let brownNoiseSection = ScienceSection(
        id: "brown_noise",
        title: String(localized: "Brown Noise"),
        icon: "cloud.fill",
        content: [
            ScienceArticle(
                id: "brown_noise_overview",
                title: String(localized: "What Is Brown Noise?"),
                body: String(localized: "Brown noise (also called Brownian noise) emphasizes lower frequencies, producing a deep, rich rumble. It sounds like a strong wind, a roaring river, or distant thunder."),
                icon: "wind",
                bulletPoints: [
                    String(localized: "Stronger energy at lower frequencies than white noise"),
                    String(localized: "Named after Robert Brown and Brownian motion, not the color"),
                    String(localized: "Sounds deeper, warmer, and more \"bassy\" than white noise"),
                    String(localized: "SoundScape offers both regular and deep brown noise variants")
                ]
            ),
            ScienceArticle(
                id: "brown_noise_benefits",
                title: String(localized: "Why People Prefer Brown Noise"),
                body: String(localized: "Many people find brown noise more soothing than white noise. Its deeper tone feels less \"harsh\" and more natural, like being near a waterfall or inside a cozy cabin during a storm."),
                icon: "heart.fill",
                bulletPoints: [
                    String(localized: "Often perceived as more calming and less fatiguing"),
                    String(localized: "Lower frequencies feel warm and enveloping"),
                    String(localized: "Popular for deep relaxation and sleep"),
                    String(localized: "Some users find it helps with anxiety and overthinking")
                ]
            )
        ]
    )
}
