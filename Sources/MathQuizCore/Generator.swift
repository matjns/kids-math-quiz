import Foundation

enum ProblemAudit: Equatable {
    case addition(Int, Int)
    case subtraction(Int, Int)
    case multiplication(Int, Int)
    case division(dividend: Int, divisor: Int)
    case shaded(numerator: Int, denominator: Int)
    case greater(Fraction, Fraction)
    case simplify(from: Fraction, to: Fraction)
    case fractionAdd(Fraction, Fraction)
    case fractionSubtract(Fraction, Fraction)
    case fractionOf(numerator: Int, denominator: Int, whole: Int)
    case digitValue(number: Int, place: Int)
    case digitIdentity(number: Int, place: Int)
    case expanded(hundreds: Int, tens: Int, ones: Int)
    case compare(Int, Int)
    case round(number: Int, place: Int)
    case word(answer: Int, shown: [Int])
    case wordFraction(numerator: Int, denominator: Int, shown: [Int])
}

struct GeneratedQuestion: Equatable {
    var topic: Topic
    var level: Int
    var prompt: String
    var entry: EntryStyle
    var choices: [String]
    var answer: AnswerKey
    var hint: String
    var solution: String
    var audit: ProblemAudit

    func question(id: UUID) -> Question {
        Question(
            id: id,
            topic: topic,
            level: level,
            prompt: prompt,
            entry: entry,
            choices: choices,
            answer: answer,
            hint: hint,
            solution: solution
        )
    }
}

func pack(
    topic: Topic,
    level: Int,
    prompt: String,
    answer: AnswerKey,
    hint preferred: String,
    fallback: String,
    solution: String,
    choices: [String] = [],
    audit: ProblemAudit
) -> GeneratedQuestion {
    let entry: EntryStyle
    switch answer {
    case .integer:
        entry = .wholeNumber
    case .fraction:
        entry = .fraction
    case .choice:
        entry = .choices
    }
    let hint = NumericText.hint(preferred: preferred, fallback: fallback, hiding: answer.hiddenTokens)
    return GeneratedQuestion(
        topic: topic,
        level: level,
        prompt: prompt,
        entry: entry,
        choices: choices,
        answer: answer,
        hint: hint,
        solution: solution,
        audit: audit
    )
}

func shuffled(_ values: [String], rng: inout SplitMix64) -> [String] {
    var copy = values
    guard copy.count > 1 else { return copy }
    for index in stride(from: copy.count - 1, through: 1, by: -1) {
        copy.swapAt(index, rng.int(0...index))
    }
    return copy
}

struct QuestionGenerator {
    var rng: SplitMix64

    init(seed: UInt64) {
        self.init(rng: SplitMix64(seed: seed))
    }

    init(rng: SplitMix64) {
        self.rng = rng
    }

    mutating func make(topic: Topic, level: Int) -> Question {
        generated(topic: topic, level: level).question(id: UUID())
    }

    mutating func generated(topic: Topic, level: Int) -> GeneratedQuestion {
        let clamped = min(max(level, 1), QuizRules.maxLevel)
        switch topic {
        case .addition:
            return AdditionProblems.make(level: clamped, rng: &rng)
        case .subtraction:
            return SubtractionProblems.make(level: clamped, rng: &rng)
        case .multiplication:
            return MultiplicationProblems.make(level: clamped, rng: &rng)
        case .division:
            return DivisionProblems.make(level: clamped, rng: &rng)
        case .fractions:
            return FractionProblems.make(level: clamped, rng: &rng)
        case .placeValue:
            return PlaceValueProblems.make(level: clamped, rng: &rng)
        case .wordProblems:
            return WordProblems.make(level: clamped, rng: &rng)
        }
    }
}

public enum RoundPlan {
    public static func topics(skills: [Topic: Skill], count: Int, rng: inout SplitMix64) -> [Topic] {
        let all = Array(Topic.allCases)
        let wanted = max(0, count)
        guard wanted > 0, !all.isEmpty else { return [] }

        let ranked = all
            .map { topic -> (Topic, Int, UInt64) in
                (topic, skills[topic]?.level ?? 1, rng.next())
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 < rhs.1 }
                return lhs.2 < rhs.2
            }
            .map(\.0)

        var result: [Topic] = []
        var counts: [Topic: Int] = [:]
        let variety = min(wanted, min(4, all.count))
        for topic in ranked where result.count < variety {
            result.append(topic)
            counts[topic, default: 0] += 1
        }

        var spins = 0
        while result.count < wanted, spins < wanted * 8 {
            spins += 1
            let candidates = all.filter { (counts[$0] ?? 0) < QuizRules.maxOfOneTopic }
            if candidates.isEmpty { break }
            let picked = weighted(candidates, skills: skills, rng: &rng)
            result.append(picked)
            counts[picked, default: 0] += 1
        }
        return result
    }

    /// Lower levels are more likely to show up again in the rest of the round.
    static func weight(_ level: Int) -> Int {
        QuizRules.maxLevel + 2 - min(max(level, 1), QuizRules.maxLevel)
    }

    private static func weighted(_ topics: [Topic], skills: [Topic: Skill], rng: inout SplitMix64) -> Topic {
        let weights = topics.map { weight(skills[$0]?.level ?? 1) }
        let total = max(1, weights.reduce(0, +))
        var roll = rng.int(0...(total - 1))
        for (topic, topicWeight) in zip(topics, weights) {
            roll -= topicWeight
            if roll < 0 { return topic }
        }
        return topics[topics.count - 1]
    }
}
