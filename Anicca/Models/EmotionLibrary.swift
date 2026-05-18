import Foundation

enum EmotionLibrary {
    static let all: [Emotion] = root + sacral + solar + heart + throat + thirdEye + crown

    static let byCenter: [EnergyCenter: [Emotion]] = [
        .root: root,
        .sacral: sacral,
        .solar: solar,
        .heart: heart,
        .throat: throat,
        .thirdEye: thirdEye,
        .crown: crown
    ]

    static func emotion(named name: String, in center: EnergyCenter) -> Emotion? {
        byCenter[center]?.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    static func emotion(byId id: UUID) -> Emotion? {
        all.first { $0.id == id }
    }

    // MARK: - Root
    static let root: [Emotion] = [
        Emotion(name: "Anxious", center: .root, valence: .negative, sfSymbol: "shield.fill", description: "Feeling a pervasive sense of unease, worry, or dread.", synonyms: ["Scared", "Afraid", "Fearful", "Nervous", "Worried", "Apprehensive", "Edgy", "Tense"]),
        Emotion(name: "Insecure", center: .root, valence: .negative, sfSymbol: "shield.fill", description: "Lacking confidence in your safety, foundation, or worth.", synonyms: ["Unsafe", "Uncertain", "Vulnerable", "Shaky", "Doubtful"]),
        Emotion(name: "Disconnected", center: .root, valence: .negative, sfSymbol: "shield.fill", description: "Feeling separated from your body, environment, or reality.", synonyms: ["Detached", "Spaced out", "Dissociated", "Unanchored", "Isolated"]),
        Emotion(name: "Restless", center: .root, valence: .negative, sfSymbol: "shield.fill", description: "Unable to find peace, physical comfort, or stillness.", synonyms: ["Fidgety", "Agitated", "Uneasy", "Jumpy", "Unsettled"]),
        Emotion(name: "Cautious", center: .root, valence: .neutral, sfSymbol: "shield.fill", description: "Carefully assessing your surroundings or situation.", synonyms: ["Careful", "Guarded", "Wary", "Watchful", "Hesitant"]),
        Emotion(name: "Still", center: .root, valence: .neutral, sfSymbol: "shield.fill", description: "A state of physical or mental motionlessness.", synonyms: ["Quiet", "Motionless", "Calm", "Resting", "Unmoving"]),
        Emotion(name: "Settling", center: .root, valence: .neutral, sfSymbol: "shield.fill", description: "The process of slowly finding your grounding or place.", synonyms: ["Stabilizing", "Calming down", "Adjusting", "Landing", "Centering"]),
        Emotion(name: "Present", center: .root, valence: .neutral, sfSymbol: "shield.fill", description: "Being fully engaged in the current moment.", synonyms: ["Here", "Mindful", "Attentive", "Focused", "Aware"]),
        Emotion(name: "Grounded", center: .root, valence: .positive, sfSymbol: "shield.fill", description: "Feeling solidly rooted in your body and the earth.", synonyms: ["Anchored", "Centered", "Solid", "Balanced", "Earthed"]),
        Emotion(name: "Secure", center: .root, valence: .positive, sfSymbol: "shield.fill", description: "Free from danger or the fear of threat.", synonyms: ["Safe", "Protected", "Certain", "Confident", "Assured"]),
        Emotion(name: "Stable", center: .root, valence: .positive, sfSymbol: "shield.fill", description: "Steady, unchanging, and emotionally regulated.", synonyms: ["Steady", "Firm", "Reliable", "Constant", "Unshaken"]),
        Emotion(name: "Safe", center: .root, valence: .positive, sfSymbol: "shield.fill", description: "A deep knowing that you are protected from harm.", synonyms: ["Secure", "Sheltered", "Unharmed", "Defended", "Snug"]),
        Emotion(name: "Supported", center: .root, valence: .positive, sfSymbol: "shield.fill", description: "Feeling held and backed up by life or others.", synonyms: ["Held", "Backed", "Cared for", "Nourished", "Sustained"]),
        Emotion(name: "Rooted", center: .root, valence: .positive, sfSymbol: "shield.fill", description: "Deeply connected to your foundations and origins.", synonyms: ["Established", "Firm", "Deep-seated", "Belonging", "Entrenched"])
    ]

    // MARK: - Sacral
    static let sacral: [Emotion] = [
        Emotion(name: "Stuck", center: .sacral, valence: .negative, sfSymbol: "drop.fill", description: "Feeling trapped, unable to move forward or create.", synonyms: ["Blocked", "Trapped", "Stagnant", "Immobilized", "Frozen"]),
        Emotion(name: "Numb", center: .sacral, valence: .negative, sfSymbol: "drop.fill", description: "Lacking feeling or emotional response to life.", synonyms: ["Deadened", "Insensible", "Unfeeling", "Blank", "Desensitized"]),
        Emotion(name: "Guilty", center: .sacral, valence: .negative, sfSymbol: "drop.fill", description: "A heavy feeling of having done wrong or failed.", synonyms: ["Ashamed", "Remorseful", "Regretful", "Blameworthy", "At fault"]),
        Emotion(name: "Uninspired", center: .sacral, valence: .negative, sfSymbol: "drop.fill", description: "Lacking creative energy, passion, or motivation.", synonyms: ["Apathetic", "Bored", "Unmotivated", "Flat", "Lifeless"]),
        Emotion(name: "Stirring", center: .sacral, valence: .neutral, sfSymbol: "drop.fill", description: "A subtle awakening or movement of desire.", synonyms: ["Awakening", "Rousing", "Moving", "Brewing", "Simmering"]),
        Emotion(name: "Yearning", center: .sacral, valence: .neutral, sfSymbol: "drop.fill", description: "A deep, enduring longing for something or someone.", synonyms: ["Longing", "Craving", "Desiring", "Aching", "Pining"]),
        Emotion(name: "Yielding", center: .sacral, valence: .neutral, sfSymbol: "drop.fill", description: "Softening and allowing things to happen naturally.", synonyms: ["Surrendering", "Allowing", "Submitting", "Softening", "Accepting"]),
        Emotion(name: "Fluid", center: .sacral, valence: .neutral, sfSymbol: "drop.fill", description: "Capable of flowing and changing easily.", synonyms: ["Adaptable", "Flexible", "Malleable", "Supple", "Shifting"]),
        Emotion(name: "Playful", center: .sacral, valence: .positive, sfSymbol: "drop.fill", description: "Full of fun, lightheartedness, and joy.", synonyms: ["Fun", "Mischievous", "Lively", "Spirited", "Frisky"]),
        Emotion(name: "Creative", center: .sacral, valence: .positive, sfSymbol: "drop.fill", description: "Bursting with imagination and original ideas.", synonyms: ["Inventive", "Imaginative", "Inspired", "Artistic", "Innovative"]),
        Emotion(name: "Passionate", center: .sacral, valence: .positive, sfSymbol: "drop.fill", description: "Driven by intense, enthusiastic feelings.", synonyms: ["Fiery", "Intense", "Fervent", "Zealous", "Enthusiastic"]),
        Emotion(name: "Flowing", center: .sacral, valence: .positive, sfSymbol: "drop.fill", description: "Moving effortlessly and continuously with life.", synonyms: ["Gliding", "Smooth", "Continuous", "Unblocked", "Effortless"]),
        Emotion(name: "Joyful", center: .sacral, valence: .positive, sfSymbol: "drop.fill", description: "Experiencing great pleasure, happiness, and delight.", synonyms: ["Happy", "Glad", "Joy", "Delighted", "Cheerful", "Elated", "Ecstatic"]),
        Emotion(name: "Sensual", center: .sacral, valence: .positive, sfSymbol: "drop.fill", description: "Deeply connected to physical pleasure and the senses.", synonyms: ["Lush", "Voluptuous", "Physical", "Pleasurable", "Tactile"])
    ]

    // MARK: - Solar Plexus
    static let solar: [Emotion] = [
        Emotion(name: "Powerless", center: .solar, valence: .negative, sfSymbol: "sun.max.fill", description: "Lacking the capacity, strength, or agency to act.", synonyms: ["Helpless", "Weak", "Vulnerable", "Incapable", "Impotent"]),
        Emotion(name: "Inadequate", center: .solar, valence: .negative, sfSymbol: "sun.max.fill", description: "Feeling you are not enough or lacking worth.", synonyms: ["Deficient", "Unworthy", "Inferior", "Lacking", "Not enough"]),
        Emotion(name: "Frustrated", center: .solar, valence: .negative, sfSymbol: "sun.max.fill", description: "Annoyed at being hindered or unable to progress.", synonyms: ["Angry", "Mad", "Furious", "Aggravated", "Irritated", "Annoyed", "Thwarted"]),
        Emotion(name: "Overwhelmed", center: .solar, valence: .negative, sfSymbol: "sun.max.fill", description: "Burdened by too much intensity or responsibility.", synonyms: ["Swamped", "Burdened", "Crushed", "Drowning", "Defeated"]),
        Emotion(name: "Hesitant", center: .solar, valence: .neutral, sfSymbol: "sun.max.fill", description: "Pausing before acting due to uncertainty.", synonyms: ["Reluctant", "Unsure", "Tentative", "Timid", "Pausing"]),
        Emotion(name: "Ambitious", center: .solar, valence: .neutral, sfSymbol: "sun.max.fill", description: "Having a strong desire for success or achievement.", synonyms: ["Aspiring", "Eager", "Goal-oriented", "Striving", "Hungry"]),
        Emotion(name: "Driven", center: .solar, valence: .neutral, sfSymbol: "sun.max.fill", description: "Highly motivated and compelled by an internal force.", synonyms: ["Motivated", "Compelled", "Focused", "Pushed", "Obsessed"]),
        Emotion(name: "Determined", center: .solar, valence: .neutral, sfSymbol: "sun.max.fill", description: "Firm in purpose and resolute in intention.", synonyms: ["Resolute", "Steadfast", "Unwavering", "Persistent", "Stubborn"]),
        Emotion(name: "Confident", center: .solar, valence: .positive, sfSymbol: "sun.max.fill", description: "A deep belief in your own abilities and worth.", synonyms: ["Self-assured", "Certain", "Secure", "Positive", "Poised"]),
        Emotion(name: "Empowered", center: .solar, valence: .positive, sfSymbol: "sun.max.fill", description: "Feeling strong, capable, and in charge of your life.", synonyms: ["Strong", "Authorized", "Enabled", "Commanding", "Sovereign"]),
        Emotion(name: "Capable", center: .solar, valence: .positive, sfSymbol: "sun.max.fill", description: "Having the ability and fitness to achieve things.", synonyms: ["Competent", "Able", "Adept", "Proficient", "Skilled"]),
        Emotion(name: "Bold", center: .solar, valence: .positive, sfSymbol: "sun.max.fill", description: "Willing to take risks and act with courage.", synonyms: ["Courageous", "Daring", "Fearless", "Brave", "Audacious"]),
        Emotion(name: "Radiant", center: .solar, valence: .positive, sfSymbol: "sun.max.fill", description: "Sending out light, joy, or profound confidence.", synonyms: ["Glowing", "Shining", "Brilliant", "Luminous", "Bright"]),
        Emotion(name: "Assured", center: .solar, valence: .positive, sfSymbol: "sun.max.fill", description: "Quietly confident and free from doubt.", synonyms: ["Certain", "Unworried", "Guaranteed", "Convinced", "Unhesitating"])
    ]

    // MARK: - Heart
    static let heart: [Emotion] = [
        Emotion(name: "Lonely", center: .heart, valence: .negative, sfSymbol: "heart.fill", description: "Feeling sadness because one has no friends or company.", synonyms: ["Sad", "Unhappy", "Blue", "Isolated", "Alone", "Lonesome", "Abandoned", "Forsaken"]),
        Emotion(name: "Closed", center: .heart, valence: .negative, sfSymbol: "heart.fill", description: "Emotionally unavailable or refusing to connect.", synonyms: ["Shut down", "Distant", "Cold", "Withdrawn", "Unapproachable"]),
        Emotion(name: "Hurt", center: .heart, valence: .negative, sfSymbol: "heart.fill", description: "Feeling emotional pain or distress from a wound.", synonyms: ["Wounded", "Pained", "Aching", "Injured", "Betrayed"]),
        Emotion(name: "Grieving", center: .heart, valence: .negative, sfSymbol: "heart.fill", description: "Experiencing deep sorrow, especially over a loss.", synonyms: ["Sad", "Sorrow", "Grief", "Mourning", "Sorrowful", "Heartbroken", "Devastated", "Bereft"]),
        Emotion(name: "Guarded", center: .heart, valence: .neutral, sfSymbol: "heart.fill", description: "Cautious and keeping emotional distance for protection.", synonyms: ["Defensive", "Wary", "Reserved", "Protective", "Careful"]),
        Emotion(name: "Receptive", center: .heart, valence: .neutral, sfSymbol: "heart.fill", description: "Willing to consider or accept new suggestions and ideas.", synonyms: ["Open-minded", "Responsive", "Approachable", "Accessible", "Welcoming"]),
        Emotion(name: "Tender", center: .heart, valence: .neutral, sfSymbol: "heart.fill", description: "Showing gentleness and concern or sympathy.", synonyms: ["Gentle", "Soft", "Delicate", "Mild", "Sensitive"]),
        Emotion(name: "Vulnerable", center: .heart, valence: .neutral, sfSymbol: "heart.fill", description: "Exposed to the possibility of being attacked or harmed, either physically or emotionally.", synonyms: ["Exposed", "Open", "Defenseless", "Sensitive", "Naked"]),
        Emotion(name: "Loving", center: .heart, valence: .positive, sfSymbol: "heart.fill", description: "Feeling or showing love or great care.", synonyms: ["Affectionate", "Caring", "Warm", "Adoring", "Devoted"]),
        Emotion(name: "Compassionate", center: .heart, valence: .positive, sfSymbol: "heart.fill", description: "Feeling or showing sympathy and concern for others.", synonyms: ["Sympathetic", "Empathetic", "Kind", "Understanding", "Caring"]),
        Emotion(name: "Grateful", center: .heart, valence: .positive, sfSymbol: "heart.fill", description: "Feeling or showing an appreciation of kindness.", synonyms: ["Thankful", "Appreciative", "Indebted", "Obliged", "Blessed"]),
        Emotion(name: "Accepted", center: .heart, valence: .positive, sfSymbol: "heart.fill", description: "Believed or recognized as valid or correct.", synonyms: ["Embraced", "Welcomed", "Included", "Validated", "Received"]),
        Emotion(name: "Forgiving", center: .heart, valence: .positive, sfSymbol: "heart.fill", description: "Ready and willing to forgive.", synonyms: ["Pardoning", "Merciful", "Clement", "Lenient", "Excusing"]),
        Emotion(name: "Peaceful", center: .heart, valence: .positive, sfSymbol: "heart.fill", description: "Free from disturbance; tranquil.", synonyms: ["Tranquil", "Calm", "Placid", "Serene", "Restful"])
    ]

    // MARK: - Throat
    static let throat: [Emotion] = [
        Emotion(name: "Misunderstood", center: .throat, valence: .negative, sfSymbol: "waveform", description: "Incorrectly interpreted or judged.", synonyms: ["Misinterpreted", "Misjudged", "Confused", "Unappreciated", "Misknowing"]),
        Emotion(name: "Silenced", center: .throat, valence: .negative, sfSymbol: "waveform", description: "Prohibited or prevented from speaking.", synonyms: ["Muted", "Quietened", "Gagged", "Muffled", "Censored"]),
        Emotion(name: "Constricted", center: .throat, valence: .negative, sfSymbol: "waveform", description: "Feeling tight or restricted, unable to express freely.", synonyms: ["Tight", "Restricted", "Choked", "Stifled", "Strangled"]),
        Emotion(name: "Withdrawn", center: .throat, valence: .negative, sfSymbol: "waveform", description: "Not wanting to communicate with other people.", synonyms: ["Introverted", "Uncommunicative", "Silent", "Quiet", "Reserved"]),
        Emotion(name: "Reflective", center: .throat, valence: .neutral, sfSymbol: "waveform", description: "Providing a reflection; capable of reflecting light or other radiation.", synonyms: ["Thoughtful", "Pensive", "Contemplative", "Meditative", "Musing"]),
        Emotion(name: "Listening", center: .throat, valence: .neutral, sfSymbol: "waveform", description: "Give one's attention to a sound.", synonyms: ["Hearing", "Attentive", "Heeding", "Observing", "Noting"]),
        Emotion(name: "Processing", center: .throat, valence: .neutral, sfSymbol: "waveform", description: "Dealing with or understanding information or feelings.", synonyms: ["Digest", "Absorb", "Comprehend", "Integrate", "Analyze"]),
        Emotion(name: "Honest", center: .throat, valence: .neutral, sfSymbol: "waveform", description: "Free of deceit and untruthfulness; sincere.", synonyms: ["Truthful", "Sincere", "Candid", "Frank", "Direct"]),
        Emotion(name: "Expressive", center: .throat, valence: .positive, sfSymbol: "waveform", description: "Effectively conveying thought or feeling.", synonyms: ["Articulate", "Communicative", "Eloquent", "Vocal", "Demonstrative"]),
        Emotion(name: "Authentic", center: .throat, valence: .positive, sfSymbol: "waveform", description: "Of undisputed origin; genuine.", synonyms: ["Genuine", "Real", "True", "Original", "Legitimate"]),
        Emotion(name: "Heard", center: .throat, valence: .positive, sfSymbol: "waveform", description: "Perceived by the ear; listened to.", synonyms: ["Acknowledged", "Understood", "Recognized", "Validated", "Listened to"]),
        Emotion(name: "Understood", center: .throat, valence: .positive, sfSymbol: "waveform", description: "Perceived the intended meaning of (words, a language, or speaker).", synonyms: ["Comprehended", "Grasped", "Fathomed", "Appreciated", "Seen"]),
        Emotion(name: "Clear", center: .throat, valence: .positive, sfSymbol: "waveform", description: "Easy to perceive, understand, or interpret.", synonyms: ["Lucid", "Transparent", "Obvious", "Evident", "Plain"]),
        Emotion(name: "Articulate", center: .throat, valence: .positive, sfSymbol: "waveform", description: "Having or showing the ability to speak fluently and coherently.", synonyms: ["Fluent", "Eloquent", "Effective", "Persuasive", "Lucid"])
    ]

    // MARK: - Third Eye
    static let thirdEye: [Emotion] = [
        Emotion(name: "Confused", center: .thirdEye, valence: .negative, sfSymbol: "eye.fill", description: "Unable to think clearly; bewildered.", synonyms: ["Baffled", "Puzzled", "Perplexed", "Bewildered", "Disoriented"]),
        Emotion(name: "Scattered", center: .thirdEye, valence: .negative, sfSymbol: "eye.fill", description: "Lacking focus or direction; disorganized.", synonyms: ["Disorganized", "Unfocused", "Dispersed", "Distracted", "Fragmented"]),
        Emotion(name: "Doubtful", center: .thirdEye, valence: .negative, sfSymbol: "eye.fill", description: "Feeling uncertain about something.", synonyms: ["Uncertain", "Unsure", "Hesitant", "Skeptical", "Suspicious"]),
        Emotion(name: "Foggy", center: .thirdEye, valence: .negative, sfSymbol: "eye.fill", description: "Lacking clarity or distinctness.", synonyms: ["Hazy", "Cloudy", "Muddled", "Fuzzy", "Unclear"]),
        Emotion(name: "Contemplative", center: .thirdEye, valence: .neutral, sfSymbol: "eye.fill", description: "Expressing or involving prolonged thought.", synonyms: ["Thoughtful", "Pensive", "Reflective", "Meditative", "Musing"]),
        Emotion(name: "Observant", center: .thirdEye, valence: .neutral, sfSymbol: "eye.fill", description: "Quick to notice things.", synonyms: ["Alert", "Sharp", "Perceptive", "Attentive", "Vigilant"]),
        Emotion(name: "Wondering", center: .thirdEye, valence: .neutral, sfSymbol: "eye.fill", description: "Desiring to know something; feeling curious.", synonyms: ["Questioning", "Pondering", "Speculating", "Marveling", "Inquiring"]),
        Emotion(name: "Curious", center: .thirdEye, valence: .neutral, sfSymbol: "eye.fill", description: "Eager to know or learn something.", synonyms: ["Inquisitive", "Interested", "Prying", "Investigative", "Searching"]),
        Emotion(name: "Intuitive", center: .thirdEye, valence: .positive, sfSymbol: "eye.fill", description: "Using or based on what one feels to be true even without conscious reasoning.", synonyms: ["Instinctive", "Innate", "Spontaneous", "Untaught", "Visceral"]),
        Emotion(name: "Aware", center: .thirdEye, valence: .positive, sfSymbol: "eye.fill", description: "Having knowledge or perception of a situation or fact.", synonyms: ["Conscious", "Mindful", "Cognizant", "Informed", "Sensible"]),
        Emotion(name: "Perceptive", center: .thirdEye, valence: .positive, sfSymbol: "eye.fill", description: "Having or showing sensitive insight.", synonyms: ["Insightful", "Discerning", "Astute", "Observant", "Sharp"]),
        Emotion(name: "Insightful", center: .thirdEye, valence: .positive, sfSymbol: "eye.fill", description: "Having or showing an accurate and deep understanding.", synonyms: ["Profound", "Deep", "Astute", "Shrewd", "Wise"]),
        Emotion(name: "Clear-minded", center: .thirdEye, valence: .positive, sfSymbol: "eye.fill", description: "Having a mind free from confusion or ambiguity.", synonyms: ["Lucid", "Focused", "Sharp", "Rational", "Logical"]),
        Emotion(name: "Focused", center: .thirdEye, valence: .positive, sfSymbol: "eye.fill", description: "Directing a great deal of attention, interest, or activity towards a particular aim.", synonyms: ["Concentrated", "Attentive", "Absorbed", "Engrossed", "Dedicated"])
    ]

    // MARK: - Crown
    static let crown: [Emotion] = [
        Emotion(name: "Meaningless", center: .crown, valence: .negative, sfSymbol: "sparkles", description: "Having no meaning or significance.", synonyms: ["Pointless", "Purposeless", "Vain", "Empty", "Futile"]),
        Emotion(name: "Disconnected", center: .crown, valence: .negative, sfSymbol: "sparkles", description: "Having had a connection broken.", synonyms: ["Separated", "Detached", "Isolated", "Cut off", "Unlinked"]),
        Emotion(name: "Cynical", center: .crown, valence: .negative, sfSymbol: "sparkles", description: "Believing that people are motivated by self-interest; distrustful of human sincerity or integrity.", synonyms: ["Skeptical", "Doubtful", "Suspicious", "Pessimistic", "Misanthropic"]),
        Emotion(name: "Hollow", center: .crown, valence: .negative, sfSymbol: "sparkles", description: "Without significance.", synonyms: ["Empty", "Vacant", "Void", "Barren", "Desolate"]),
        Emotion(name: "Searching", center: .crown, valence: .neutral, sfSymbol: "sparkles", description: "Trying to find something by looking or otherwise seeking carefully and thoroughly.", synonyms: ["Seeking", "Looking", "Hunting", "Exploring", "Questing"]),
        Emotion(name: "Surrendering", center: .crown, valence: .neutral, sfSymbol: "sparkles", description: "Cease resistance to an enemy or opponent and submit to their authority.", synonyms: ["Yielding", "Submitting", "Giving in", "Capitulating", "Relinquishing"]),
        Emotion(name: "Open", center: .crown, valence: .neutral, sfSymbol: "sparkles", description: "Allowing access, passage, or a view through an empty space; not closed or blocked.", synonyms: ["Unclosed", "Unlocked", "Unfastened", "Ajar", "Unsealed"]),
        Emotion(name: "Reflective", center: .crown, valence: .neutral, sfSymbol: "sparkles", description: "Relating to or characterized by deep thought; thoughtful.", synonyms: ["Pensive", "Thoughtful", "Contemplative", "Meditative", "Musing"]),
        Emotion(name: "Connected", center: .crown, valence: .positive, sfSymbol: "sparkles", description: "Brought together or into contact so that a real or notional link is established.", synonyms: ["Linked", "Attached", "Joined", "United", "Coupled"]),
        Emotion(name: "Whole", center: .crown, valence: .positive, sfSymbol: "sparkles", description: "All of; entire.", synonyms: ["Complete", "Full", "Entire", "Total", "Unbroken"]),
        Emotion(name: "Purposeful", center: .crown, valence: .positive, sfSymbol: "sparkles", description: "Having or showing determination or resolve.", synonyms: ["Determined", "Resolute", "Steadfast", "Intent", "Firm"]),
        Emotion(name: "Transcendent", center: .crown, valence: .positive, sfSymbol: "sparkles", description: "Beyond or above the range of normal or merely physical human experience.", synonyms: ["Mystical", "Otherworldly", "Divine", "Sublime", "Ethereal"]),
        Emotion(name: "Blissful", center: .crown, valence: .positive, sfSymbol: "sparkles", description: "Extremely happy; full of joy.", synonyms: ["Joyous", "Ecstatic", "Euphoric", "Rapturous", "Elated"]),
        Emotion(name: "Unified", center: .crown, valence: .positive, sfSymbol: "sparkles", description: "Make or become united, uniform, or whole.", synonyms: ["United", "Integrated", "Amalgamated", "Consolidated", "Merged"])
    ]
}
