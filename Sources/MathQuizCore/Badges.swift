import Foundation

public enum Badge: String, Codable, CaseIterable, Equatable, Hashable {
    case firstStar = "first-star"
    case roundDone = "round-done"
    case streak3 = "streak-3"
    case streak5 = "streak-5"
    case streak10 = "streak-10"
    case perfectRound = "perfect-round"
    case lightningFinisher = "lightning-finisher"
    case lightningPerfect = "lightning-perfect"
    case tenCorrect = "ten-correct"
    case fiftyCorrect = "fifty-correct"
    case hundredStars = "hundred-stars"
    case regroupHero = "regroup-hero"
    case factFinder = "fact-finder"
    case fractionFriend = "fraction-friend"
    case placePro = "place-pro"
    case storySolver = "story-solver"
    case allAround = "all-around"

    public var title: String {
        switch self {
        case .firstStar: return "First star"
        case .roundDone: return "Round done"
        case .streak3: return "Hat trick"
        case .streak5: return "On a roll"
        case .streak10: return "Super streak"
        case .perfectRound: return "Perfect round"
        case .lightningFinisher: return "Lightning"
        case .lightningPerfect: return "Lightning perfect"
        case .tenCorrect: return "Spark"
        case .fiftyCorrect: return "Bright"
        case .hundredStars: return "Star jar"
        case .regroupHero: return "Regroup hero"
        case .factFinder: return "Fact finder"
        case .fractionFriend: return "Fraction friend"
        case .placePro: return "Place value pro"
        case .storySolver: return "Story solver"
        case .allAround: return "All-around"
        }
    }

    public var blurb: String {
        switch self {
        case .firstStar: return "Answer one question correctly."
        case .roundDone: return "Finish a round of 10."
        case .streak3: return "Get 3 correct in a row."
        case .streak5: return "Get 5 correct in a row."
        case .streak10: return "Get 10 correct in a row."
        case .perfectRound: return "Get every question in a round."
        case .lightningFinisher: return "Finish a lightning round."
        case .lightningPerfect: return "Get a perfect lightning round."
        case .tenCorrect: return "Answer 10 questions correctly."
        case .fiftyCorrect: return "Answer 50 questions correctly."
        case .hundredStars: return "Collect 100 stars."
        case .regroupHero: return "Reach Strong in addition or subtraction."
        case .factFinder: return "Reach Strong in multiplication or division."
        case .fractionFriend: return "Reach Steady in fractions."
        case .placePro: return "Reach Strong in place value."
        case .storySolver: return "Reach Steady in word problems."
        case .allAround: return "Get one right in every topic."
        }
    }

    public static let goalOrder: [Badge] = [
        .firstStar, .roundDone, .streak3, .streak5, .tenCorrect, .perfectRound,
        .lightningFinisher, .streak10, .fractionFriend, .storySolver, .factFinder,
        .regroupHero, .placePro, .allAround, .fiftyCorrect, .lightningPerfect, .hundredStars,
    ]
}

public enum BadgeRules {
    public static func qualifying(_ progress: QuizProgress) -> [Badge] {
        var earned: [Badge] = []
        func add(_ badge: Badge, _ ok: Bool) {
            if ok { earned.append(badge) }
        }
        add(.firstStar, progress.stars >= 1)
        add(.roundDone, progress.roundsFinished >= 1)
        add(.streak3, progress.bestStreak >= 3)
        add(.streak5, progress.bestStreak >= 5)
        add(.streak10, progress.bestStreak >= 10)
        add(.perfectRound, progress.perfectRounds >= 1)
        add(.lightningFinisher, progress.lightningRoundsFinished >= 1)
        add(.lightningPerfect, progress.perfectLightningRounds >= 1)
        add(.tenCorrect, progress.correctTotal >= 10)
        add(.fiftyCorrect, progress.correctTotal >= 50)
        add(.hundredStars, progress.stars >= 100)
        add(.regroupHero, progress.skill(for: .addition).level >= 4 || progress.skill(for: .subtraction).level >= 4)
        add(.factFinder, progress.skill(for: .multiplication).level >= 4 || progress.skill(for: .division).level >= 4)
        add(.fractionFriend, progress.skill(for: .fractions).level >= 3)
        add(.placePro, progress.skill(for: .placeValue).level >= 4)
        add(.storySolver, progress.skill(for: .wordProblems).level >= 3)
        add(.allAround, Topic.allCases.allSatisfy { progress.correctCount(for: $0) > 0 })
        return earned
    }

    public static func award(into progress: inout QuizProgress) -> [Badge] {
        let have = Set(progress.badges)
        let fresh = qualifying(progress).filter { !have.contains($0) }
        progress.badges.append(contentsOf: fresh)
        return fresh
    }

    public static func nextGoal(in progress: QuizProgress) -> Badge? {
        let have = Set(progress.badges)
        return Badge.goalOrder.first { !have.contains($0) }
    }
}
