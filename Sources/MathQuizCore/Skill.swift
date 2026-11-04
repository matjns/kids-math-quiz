import Foundation

public struct SkillChange: Equatable {
    public var skill: Skill
    public var leveledUp: Bool
    public var leveledDown: Bool
}

public struct Skill: Equatable, Codable {
    public var level: Int
    public var correctStreak: Int
    public var missStreak: Int

    public static let starting = Skill(level: 1, correctStreak: 0, missStreak: 0)

    public init(level: Int, correctStreak: Int = 0, missStreak: Int = 0) {
        self.level = min(max(level, 1), QuizRules.maxLevel)
        self.correctStreak = max(0, correctStreak)
        self.missStreak = max(0, missStreak)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let level = try container.decodeIfPresent(Int.self, forKey: .level) ?? 1
        let correctStreak = try container.decodeIfPresent(Int.self, forKey: .correctStreak) ?? 0
        let missStreak = try container.decodeIfPresent(Int.self, forKey: .missStreak) ?? 0
        self.init(level: level, correctStreak: correctStreak, missStreak: missStreak)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(level, forKey: .level)
        try container.encode(correctStreak, forKey: .correctStreak)
        try container.encode(missStreak, forKey: .missStreak)
    }

    /// A correct answer adds to the streak. Three in a row level the topic up
    /// and the streak starts over, so the new level has to be earned too.
    /// A miss clears that streak. A second miss in a row eases the topic down
    /// one step. A correct answer in between forgives the first miss.
    public func recording(correct: Bool) -> SkillChange {
        if correct {
            var streak = correctStreak + 1
            var nextLevel = level
            var leveledUp = false
            if streak >= QuizRules.streakToLevelUp, level < QuizRules.maxLevel {
                nextLevel = level + 1
                streak = 0
                leveledUp = true
            }
            let skill = Skill(level: nextLevel, correctStreak: streak, missStreak: 0)
            return SkillChange(skill: skill, leveledUp: leveledUp, leveledDown: false)
        }
        let misses = missStreak + 1
        if misses >= QuizRules.missesToLevelDown, level > 1 {
            let skill = Skill(level: level - 1, correctStreak: 0, missStreak: 0)
            return SkillChange(skill: skill, leveledUp: false, leveledDown: true)
        }
        let skill = Skill(level: level, correctStreak: 0, missStreak: misses)
        return SkillChange(skill: skill, leveledUp: false, leveledDown: false)
    }

    private enum CodingKeys: String, CodingKey {
        case level, correctStreak, missStreak
    }
}
