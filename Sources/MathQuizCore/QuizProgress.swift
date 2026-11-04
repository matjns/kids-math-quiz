import Foundation

public struct QuizProgress: Equatable {
    public var playerName: String
    public var skills: [Topic: Skill]
    public var stars: Int
    public var currentStreak: Int
    public var bestStreak: Int
    public var correctTotal: Int
    public var answeredTotal: Int
    public var roundsFinished: Int
    public var lightningRoundsFinished: Int
    public var perfectRounds: Int
    public var perfectLightningRounds: Int
    public var topicCorrect: [Topic: Int]
    public var badges: [Badge]

    public static let fresh = QuizProgress()

    public init(
        playerName: String = "",
        skills: [Topic: Skill]? = nil,
        stars: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        correctTotal: Int = 0,
        answeredTotal: Int = 0,
        roundsFinished: Int = 0,
        lightningRoundsFinished: Int = 0,
        perfectRounds: Int = 0,
        perfectLightningRounds: Int = 0,
        topicCorrect: [Topic: Int] = [:],
        badges: [Badge] = []
    ) {
        self.playerName = PlayerName.cleaned(playerName)
        var filled: [Topic: Skill] = [:]
        for topic in Topic.allCases {
            filled[topic] = skills?[topic] ?? .starting
        }
        self.skills = filled
        self.stars = max(0, stars)
        self.currentStreak = max(0, currentStreak)
        self.bestStreak = max(self.currentStreak, bestStreak)
        self.correctTotal = max(0, correctTotal)
        self.answeredTotal = max(0, answeredTotal)
        self.roundsFinished = max(0, roundsFinished)
        self.lightningRoundsFinished = max(0, lightningRoundsFinished)
        self.perfectRounds = max(0, perfectRounds)
        self.perfectLightningRounds = max(0, perfectLightningRounds)
        self.topicCorrect = topicCorrect
        self.badges = Self.uniqueBadges(badges)
    }

    public func skill(for topic: Topic) -> Skill {
        skills[topic] ?? .starting
    }

    public mutating func setSkill(_ skill: Skill, for topic: Topic) {
        skills[topic] = skill
    }

    public func correctCount(for topic: Topic) -> Int {
        topicCorrect[topic] ?? 0
    }

    private static func uniqueBadges(_ badges: [Badge]) -> [Badge] {
        var seen = Set<Badge>()
        var ordered: [Badge] = []
        for badge in badges where seen.insert(badge).inserted {
            ordered.append(badge)
        }
        return ordered
    }
}

extension QuizProgress: Codable {
    private enum CodingKeys: String, CodingKey {
        case playerName, skills, stars, currentStreak, bestStreak
        case correctTotal, answeredTotal, roundsFinished, lightningRoundsFinished
        case perfectRounds, perfectLightningRounds, topicCorrect, badges
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decodeIfPresent(String.self, forKey: .playerName) ?? ""
        let stars = try container.decodeIfPresent(Int.self, forKey: .stars) ?? 0
        let currentStreak = try container.decodeIfPresent(Int.self, forKey: .currentStreak) ?? 0
        let bestStreak = try container.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        let correctTotal = try container.decodeIfPresent(Int.self, forKey: .correctTotal) ?? 0
        let answeredTotal = try container.decodeIfPresent(Int.self, forKey: .answeredTotal) ?? 0
        let roundsFinished = try container.decodeIfPresent(Int.self, forKey: .roundsFinished) ?? 0
        let lightningRoundsFinished = try container.decodeIfPresent(Int.self, forKey: .lightningRoundsFinished) ?? 0
        let perfectRounds = try container.decodeIfPresent(Int.self, forKey: .perfectRounds) ?? 0
        let perfectLightningRounds = try container.decodeIfPresent(Int.self, forKey: .perfectLightningRounds) ?? 0
        let badgeNames = try container.decodeIfPresent([String].self, forKey: .badges) ?? []
        self.init(
            playerName: name,
            skills: Self.skills(from: container),
            stars: stars,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            correctTotal: correctTotal,
            answeredTotal: answeredTotal,
            roundsFinished: roundsFinished,
            lightningRoundsFinished: lightningRoundsFinished,
            perfectRounds: perfectRounds,
            perfectLightningRounds: perfectLightningRounds,
            topicCorrect: Self.topicCounts(from: container),
            badges: badgeNames.compactMap(Badge.init(rawValue:))
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerName, forKey: .playerName)
        try container.encode(stars, forKey: .stars)
        try container.encode(currentStreak, forKey: .currentStreak)
        try container.encode(bestStreak, forKey: .bestStreak)
        try container.encode(correctTotal, forKey: .correctTotal)
        try container.encode(answeredTotal, forKey: .answeredTotal)
        try container.encode(roundsFinished, forKey: .roundsFinished)
        try container.encode(lightningRoundsFinished, forKey: .lightningRoundsFinished)
        try container.encode(perfectRounds, forKey: .perfectRounds)
        try container.encode(perfectLightningRounds, forKey: .perfectLightningRounds)
        try container.encode(badges.map(\.rawValue), forKey: .badges)
        let skillObject = Dictionary(uniqueKeysWithValues: skills.map { ($0.key.rawValue, $0.value) })
        let countObject = Dictionary(uniqueKeysWithValues: topicCorrect.map { ($0.key.rawValue, $0.value) })
        try container.encode(skillObject, forKey: .skills)
        try container.encode(countObject, forKey: .topicCorrect)
    }

    /// Topic keys are written as words (`"addition"`) so the file is readable.
    /// Older Swift dictionary encoding used a flat array, and that still loads.
    private static func skills(from container: KeyedDecodingContainer<CodingKeys>) -> [Topic: Skill] {
        if let object = try? container.decode([String: Skill].self, forKey: .skills) {
            var stored: [Topic: Skill] = [:]
            for (key, skill) in object {
                if let topic = Topic(rawValue: key) {
                    stored[topic] = skill
                }
            }
            return stored
        }
        return (try? container.decode([Topic: Skill].self, forKey: .skills)) ?? [:]
    }

    private static func topicCounts(from container: KeyedDecodingContainer<CodingKeys>) -> [Topic: Int] {
        if let object = try? container.decode([String: Int].self, forKey: .topicCorrect) {
            var stored: [Topic: Int] = [:]
            for (key, count) in object {
                if let topic = Topic(rawValue: key) {
                    stored[topic] = count
                }
            }
            return stored
        }
        return (try? container.decode([Topic: Int].self, forKey: .topicCorrect)) ?? [:]
    }
}

public enum Scoring {
    public static func stars(correct: Bool, lightning: Bool, streakAfter: Int) -> Int {
        guard correct else { return 0 }
        var total = lightning ? 2 : 1
        if streakAfter >= 5, streakAfter.isMultiple(of: 5) {
            total += 1
        }
        return total
    }
}
