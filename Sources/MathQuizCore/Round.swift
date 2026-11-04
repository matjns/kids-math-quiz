public struct RoundSettings: Equatable {
    public var questionCount: Int
    public var lightning: Bool
    public var secondsPerQuestion: Int

    public init(questionCount: Int, lightning: Bool, secondsPerQuestion: Int = QuizRules.lightningSeconds) {
        self.questionCount = min(30, max(1, questionCount))
        self.lightning = lightning
        self.secondsPerQuestion = min(120, max(5, secondsPerQuestion))
    }

    public static let practice = RoundSettings(
        questionCount: QuizRules.questionsPerRound,
        lightning: false
    )

    public static let lightning = RoundSettings(
        questionCount: QuizRules.questionsPerRound,
        lightning: true
    )
}

public struct AnswerRecord: Equatable {
    public var topic: Topic
    public var correct: Bool
    public var timedOut: Bool
    public var stars: Int

    public init(topic: Topic, correct: Bool, timedOut: Bool, stars: Int) {
        self.topic = topic
        self.correct = correct
        self.timedOut = timedOut
        self.stars = stars
    }
}

public struct Feedback: Equatable {
    public var correct: Bool
    public var timedOut: Bool
    public var message: String
    public var hint: String?
    public var solution: String
    public var starsEarned: Int
    public var streak: Int
    public var leveledUp: Bool
    public var leveledDown: Bool
    public var levelNote: String?
    public var starNote: String?
    public var newBadges: [Badge]

    public init(
        correct: Bool,
        timedOut: Bool,
        message: String,
        hint: String?,
        solution: String,
        starsEarned: Int,
        streak: Int,
        leveledUp: Bool,
        leveledDown: Bool,
        levelNote: String?,
        starNote: String?,
        newBadges: [Badge]
    ) {
        self.correct = correct
        self.timedOut = timedOut
        self.message = message
        self.hint = hint
        self.solution = solution
        self.starsEarned = starsEarned
        self.streak = streak
        self.leveledUp = leveledUp
        self.leveledDown = leveledDown
        self.levelNote = levelNote
        self.starNote = starNote
        self.newBadges = newBadges
    }
}

public struct RoundSummary: Equatable {
    public var correct: Int
    public var total: Int
    public var stars: Int
    public var newBadges: [Badge]
    public var encouragement: String
    public var lightning: Bool

    public init(correct: Int, total: Int, stars: Int, newBadges: [Badge], encouragement: String, lightning: Bool) {
        self.correct = correct
        self.total = total
        self.stars = stars
        self.newBadges = newBadges
        self.encouragement = encouragement
        self.lightning = lightning
    }
}

public struct QuizEngine {
    public let settings: RoundSettings
    public private(set) var plan: [Topic]
    public private(set) var questions: [Question]
    public private(set) var index: Int
    public private(set) var records: [AnswerRecord]
    public private(set) var badgesThisRound: [Badge]
    private var generator: QuestionGenerator

    public init(progress: QuizProgress, settings: RoundSettings, seed: UInt64) {
        var rng = SplitMix64(seed: seed)
        let topics = RoundPlan.topics(skills: progress.skills, count: settings.questionCount, rng: &rng)
        self.init(plan: topics, settings: settings, generator: QuestionGenerator(rng: rng), progress: progress)
    }

    public init(plan: [Topic], settings: RoundSettings, seed: UInt64, progress: QuizProgress) {
        self.init(
            plan: plan,
            settings: settings,
            generator: QuestionGenerator(seed: seed),
            progress: progress
        )
    }

    public var current: Question? {
        guard index < questions.count else { return nil }
        return questions[index]
    }

    public var isComplete: Bool {
        !plan.isEmpty && records.count == plan.count
    }

    public var correctCount: Int {
        records.filter(\.correct).count
    }

    public var starsEarned: Int {
        records.reduce(0) { $0 + $1.stars }
    }

    public var summary: RoundSummary? {
        guard isComplete else { return nil }
        return RoundSummary(
            correct: correctCount,
            total: plan.count,
            stars: starsEarned,
            newBadges: badgesThisRound,
            encouragement: QuizCopy.encouragement(correct: correctCount, total: plan.count),
            lightning: settings.lightning
        )
    }

    /// An empty answer does nothing, so a stray tap is not counted as a miss.
    /// A timeout counts as a miss even if the right digits were sitting there.
    public mutating func submit(response: String, timedOut: Bool, progress: inout QuizProgress) -> Feedback? {
        guard let question = current, records.count == index else { return nil }
        if !timedOut, !EntryCheck.isReady(response, style: question.entry) {
            return nil
        }
        let correct = timedOut ? false : Grader.isCorrect(question: question, response: response)
        let change = progress.skill(for: question.topic).recording(correct: correct)
        progress.setSkill(change.skill, for: question.topic)
        if correct {
            progress.currentStreak += 1
            if progress.currentStreak > progress.bestStreak {
                progress.bestStreak = progress.currentStreak
            }
            progress.correctTotal += 1
            progress.topicCorrect[question.topic, default: 0] += 1
        } else {
            progress.currentStreak = 0
        }
        progress.answeredTotal += 1
        let stars = Scoring.stars(
            correct: correct,
            lightning: settings.lightning,
            streakAfter: progress.currentStreak
        )
        progress.stars += stars

        if index + 1 >= plan.count {
            progress.roundsFinished += 1
            if settings.lightning {
                progress.lightningRoundsFinished += 1
            }
            let correctSoFar = records.filter(\.correct).count + (correct ? 1 : 0)
            if correctSoFar == plan.count, !plan.isEmpty {
                progress.perfectRounds += 1
                if settings.lightning {
                    progress.perfectLightningRounds += 1
                }
            }
        }

        let newBadges = BadgeRules.award(into: &progress)
        badgesThisRound.append(contentsOf: newBadges)
        records.append(AnswerRecord(topic: question.topic, correct: correct, timedOut: timedOut, stars: stars))

        let message: String
        let hint: String?
        if correct {
            message = QuizCopy.correct(solution: question.solution, streak: progress.currentStreak)
            hint = nil
        } else if timedOut {
            message = QuizCopy.timedOut(solution: question.solution)
            hint = question.hint
        } else {
            message = QuizCopy.missed(solution: question.solution)
            hint = question.hint
        }
        return Feedback(
            correct: correct,
            timedOut: timedOut,
            message: message,
            hint: hint,
            solution: question.solution,
            starsEarned: stars,
            streak: progress.currentStreak,
            leveledUp: change.leveledUp,
            leveledDown: change.leveledDown,
            levelNote: change.leveledUp ? QuizCopy.levelUpNote : nil,
            starNote: QuizCopy.starsEarned(stars),
            newBadges: newBadges
        )
    }

    public mutating func advance(progress: QuizProgress) {
        guard !isComplete else { return }
        guard records.count == index + 1 else { return }
        index += 1
        guard index < plan.count else { return }
        let topic = plan[index]
        questions.append(generator.make(topic: topic, level: progress.skill(for: topic).level))
    }

    private init(plan: [Topic], settings: RoundSettings, generator: QuestionGenerator, progress: QuizProgress) {
        self.settings = settings
        self.plan = plan
        self.index = 0
        self.records = []
        self.badgesThisRound = []
        if let topic = plan.first {
            var builder = generator
            let question = builder.make(topic: topic, level: progress.skill(for: topic).level)
            self.generator = builder
            self.questions = [question]
        } else {
            self.generator = generator
            self.questions = []
        }
    }
}
