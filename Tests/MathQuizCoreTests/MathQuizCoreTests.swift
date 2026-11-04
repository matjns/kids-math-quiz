import XCTest
@testable import MathQuizCore

final class GradingTests: XCTestCase {
    func testWholeNumbersIgnoreSpacesAndLeadingZeros() {
        let question = makeQuestion(answer: .integer(56), entry: .wholeNumber)
        XCTAssertTrue(Grader.isCorrect(question: question, response: "56"))
        XCTAssertTrue(Grader.isCorrect(question: question, response: " 056 "))
        XCTAssertTrue(Grader.isCorrect(question: question, response: "+56"))
        XCTAssertFalse(Grader.isCorrect(question: question, response: "57"))
        XCTAssertFalse(Grader.isCorrect(question: question, response: ""))
        XCTAssertFalse(Grader.isCorrect(question: question, response: "56.0"))
        XCTAssertFalse(Grader.isCorrect(question: question, response: "8/7"))
        XCTAssertTrue(EntryCheck.isReady("007", style: .wholeNumber))
        XCTAssertFalse(EntryCheck.isReady("  ", style: .wholeNumber))
    }

    func testFractionsAcceptEquivalentsOnlyWhenAsked() {
        let flexible = makeQuestion(
            answer: .fraction(Fraction(2, 4), acceptEquivalent: true),
            entry: .fraction
        )
        XCTAssertTrue(Grader.isCorrect(question: flexible, response: "2/4"))
        XCTAssertTrue(Grader.isCorrect(question: flexible, response: "1/2"))
        XCTAssertTrue(Grader.isCorrect(question: flexible, response: "2 / 4"))
        XCTAssertTrue(Grader.isCorrect(question: flexible, response: "2⁄4"))
        XCTAssertFalse(Grader.isCorrect(question: flexible, response: "3/4"))
        XCTAssertFalse(Grader.isCorrect(question: flexible, response: "2/0"))
        XCTAssertFalse(Grader.isCorrect(question: flexible, response: "2/"))
        XCTAssertFalse(EntryCheck.isReady("3/0", style: .fraction))
        XCTAssertFalse(EntryCheck.isReady("3/", style: .fraction))
        XCTAssertTrue(EntryCheck.isReady("3 / 4", style: .fraction))

        let simplest = makeQuestion(
            answer: .fraction(Fraction(1, 2), acceptEquivalent: false),
            entry: .fraction
        )
        XCTAssertTrue(Grader.isCorrect(question: simplest, response: "1/2"))
        XCTAssertFalse(Grader.isCorrect(question: simplest, response: "2/4"))
        XCTAssertFalse(Grader.isCorrect(question: simplest, response: "3/6"))
    }

    func testChoicesIgnoreCaseAndExtraSpaces() {
        let question = makeQuestion(
            answer: .choice("1/2"),
            entry: .choices,
            choices: ["1/2", "1/3"]
        )
        XCTAssertTrue(Grader.isCorrect(question: question, response: "1/2"))
        XCTAssertTrue(Grader.isCorrect(question: question, response: " 1 / 2 "))
        XCTAssertFalse(Grader.isCorrect(question: question, response: "1/3"))
        XCTAssertFalse(EntryCheck.isReady("   ", style: .choices))
    }

    private func makeQuestion(answer: AnswerKey, entry: EntryStyle, choices: [String] = []) -> Question {
        Question(
            id: UUID(),
            topic: .addition,
            level: 1,
            prompt: "Question",
            entry: entry,
            choices: choices,
            answer: answer,
            hint: "A hint",
            solution: "The solution"
        )
    }
}

final class DifficultyTests: XCTestCase {
    func testThreeCorrectInARowLevelUpAndTheStreakStartsOver() {
        var skill = Skill.starting
        var last = skill.recording(correct: true)
        skill = last.skill
        XCTAssertFalse(last.leveledUp)
        XCTAssertEqual(skill.level, 1)
        last = skill.recording(correct: true)
        skill = last.skill
        XCTAssertEqual(skill.correctStreak, 2)
        last = skill.recording(correct: true)
        XCTAssertTrue(last.leveledUp)
        XCTAssertEqual(last.skill.level, 2)
        XCTAssertEqual(last.skill.correctStreak, 0)
        XCTAssertEqual(last.skill.missStreak, 0)
    }

    func testOneMissDoesNotDropALevelAndTwoMissesDo() {
        let skill = Skill(level: 3, correctStreak: 2, missStreak: 0)
        let once = skill.recording(correct: false)
        XCTAssertFalse(once.leveledDown)
        XCTAssertEqual(once.skill.level, 3)
        XCTAssertEqual(once.skill.correctStreak, 0)
        XCTAssertEqual(once.skill.missStreak, 1)

        let forgiven = once.skill.recording(correct: true)
        XCTAssertEqual(forgiven.skill.level, 3)
        XCTAssertEqual(forgiven.skill.missStreak, 0)

        let first = skill.recording(correct: false).skill
        let second = first.recording(correct: false)
        XCTAssertTrue(second.leveledDown)
        XCTAssertEqual(second.skill.level, 2)
        XCTAssertEqual(second.skill.missStreak, 0)
    }

    func testLevelStaysInsideTheRange() {
        var skill = Skill(level: 1, correctStreak: 0, missStreak: 1)
        let dropped = skill.recording(correct: false)
        XCTAssertEqual(dropped.skill.level, 1)
        XCTAssertFalse(dropped.leveledDown)

        skill = Skill(level: QuizRules.maxLevel, correctStreak: 2, missStreak: 0)
        let topped = skill.recording(correct: true)
        XCTAssertFalse(topped.leveledUp)
        XCTAssertEqual(topped.skill.level, QuizRules.maxLevel)
        XCTAssertEqual(topped.skill.correctStreak, 3)
    }

    func testDecodedSkillLevelsAreClamped() throws {
        let json = """
        {"level":99,"correctStreak":-4,"missStreak":8}
        """.data(using: .utf8)!
        let skill = try JSONDecoder().decode(Skill.self, from: json)
        XCTAssertEqual(skill.level, QuizRules.maxLevel)
        XCTAssertEqual(skill.correctStreak, 0)
        XCTAssertEqual(skill.missStreak, 8)
    }

    func testNextQuestionUsesTheNewLevel() {
        var progress = QuizProgress.fresh
        var engine = QuizEngine(
            plan: [.addition, .addition, .addition, .addition],
            settings: RoundSettings(questionCount: 4, lightning: false),
            seed: 11,
            progress: progress
        )
        let expectedLevels = [1, 1, 1, 2]
        for expected in expectedLevels {
            let question = try! XCTUnwrap(engine.current)
            XCTAssertEqual(question.topic, .addition)
            XCTAssertEqual(question.level, expected)
            let feedback = engine.submit(
                response: Grader.canonicalResponse(for: question),
                timedOut: false,
                progress: &progress
            )
            XCTAssertEqual(feedback?.correct, true)
            engine.advance(progress: progress)
        }
        XCTAssertEqual(progress.skill(for: .addition).level, 2)
        XCTAssertEqual(progress.skill(for: .subtraction).level, 1)
        XCTAssertTrue(engine.isComplete)
        XCTAssertEqual(progress.roundsFinished, 1)
        XCTAssertEqual(progress.perfectRounds, 1)
        XCTAssertEqual(progress.badges.contains(.perfectRound), true)
        XCTAssertEqual(progress.badges.contains(.firstStar), true)
    }

    func testTimeoutCountsAsAMissAndShowsTheHint() {
        var progress = QuizProgress.fresh
        progress.setSkill(Skill(level: 4, correctStreak: 0, missStreak: 1), for: .multiplication)
        var engine = QuizEngine(
            plan: [.multiplication],
            settings: RoundSettings(questionCount: 1, lightning: true),
            seed: 3,
            progress: progress
        )
        let feedback = engine.submit(response: "99999", timedOut: true, progress: &progress)
        XCTAssertEqual(feedback?.correct, false)
        XCTAssertEqual(feedback?.timedOut, true)
        XCTAssertEqual(feedback?.hint?.isEmpty, false)
        XCTAssertTrue(feedback?.message.contains("Time's up") == true)
        XCTAssertEqual(progress.skill(for: .multiplication).level, 3)
        XCTAssertEqual(progress.stars, 0)
        XCTAssertEqual(progress.lightningRoundsFinished, 1)
    }

    func testEmptyAnswerIsNotSubmitted() {
        var progress = QuizProgress.fresh
        var engine = QuizEngine(
            plan: [.addition],
            settings: .practice,
            seed: 1,
            progress: progress
        )
        XCTAssertNil(engine.submit(response: "   ", timedOut: false, progress: &progress))
        XCTAssertEqual(progress.answeredTotal, 0)
        XCTAssertFalse(engine.isComplete)
    }

    func testStarsAndAnUnfinishedRound() {
        var progress = QuizProgress.fresh
        progress.currentStreak = 4
        var engine = QuizEngine(
            plan: [.division, .division, .division, .division],
            settings: RoundSettings(questionCount: 4, lightning: true),
            seed: 8,
            progress: progress
        )
        let question = try! XCTUnwrap(engine.current)
        let feedback = engine.submit(
            response: Grader.canonicalResponse(for: question),
            timedOut: false,
            progress: &progress
        )
        XCTAssertEqual(feedback?.starsEarned, 3)
        XCTAssertEqual(feedback?.starNote, "3 stars")
        XCTAssertEqual(progress.currentStreak, 5)
        XCTAssertEqual(progress.roundsFinished, 0)
        engine.advance(progress: progress)
        _ = engine.submit(response: "0", timedOut: false, progress: &progress)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.bestStreak, 5)
        XCTAssertEqual(progress.roundsFinished, 0)
        XCTAssertTrue(progress.badges.contains(.streak5))
    }

    func testPracticeIsUntimedAndLightningIsOptional() {
        XCTAssertFalse(RoundSettings.practice.lightning)
        XCTAssertEqual(RoundSettings.practice.questionCount, 10)
        XCTAssertTrue(RoundSettings.lightning.lightning)
        XCTAssertEqual(RoundSettings.lightning.secondsPerQuestion, 20)
        XCTAssertEqual(QuizRules.lightningSeconds, 20)
        let engine = QuizEngine(progress: .fresh, settings: .practice, seed: 4)
        XCTAssertEqual(engine.plan.count, 10)
        XCTAssertEqual(engine.questions.count, 1)
        XCTAssertFalse(engine.settings.lightning)
    }
}

final class RoundPlanTests: XCTestCase {
    func testRoundsMixTopicsAndCapRepeats() {
        var totals: [Topic: Int] = [:]
        var skills: [Topic: Skill] = [:]
        for topic in Topic.allCases {
            skills[topic] = Skill(level: topic == .fractions ? 1 : 5)
        }
        for seed in 0..<30 {
            var rng = SplitMix64(seed: UInt64(seed + 20))
            let plan = RoundPlan.topics(skills: skills, count: 10, rng: &rng)
            XCTAssertEqual(plan.count, 10)
            XCTAssertGreaterThanOrEqual(Set(plan).count, 4)
            for topic in Topic.allCases {
                let count = plan.filter { $0 == topic }.count
                XCTAssertLessThanOrEqual(count, QuizRules.maxOfOneTopic)
                totals[topic, default: 0] += count
            }
            XCTAssertGreaterThanOrEqual(plan.filter { $0 == .fractions }.count, 1)
        }
        for topic in Topic.allCases where topic != .fractions {
            XCTAssertGreaterThan(totals[.fractions] ?? 0, totals[topic] ?? 0)
        }
        XCTAssertGreaterThan(RoundPlan.weight(1), RoundPlan.weight(5))
    }
}

final class GeneratorTests: XCTestCase {
    func testQuestionsMatchTheirMathAndHideTheAnswerInTheHint() {
        for seed in 1...12 {
            for topic in Topic.allCases {
                for level in 1...QuizRules.maxLevel {
                    var generator = QuestionGenerator(seed: UInt64(seed * 100 + level * 10 + topicIndex(topic)))
                    let question = generator.generated(topic: topic, level: level)
                    assertSound(question)
                }
            }
        }
    }

    func testTheSameSeedRepeatsTheSameQuestion() {
        for topic in Topic.allCases {
            var first = QuestionGenerator(seed: 42)
            var second = QuestionGenerator(seed: 42)
            let left = first.generated(topic: topic, level: 3)
            let right = second.generated(topic: topic, level: 3)
            XCTAssertEqual(left.prompt, right.prompt)
            XCTAssertEqual(left.answer, right.answer)
            XCTAssertEqual(left.hint, right.hint)
            XCTAssertEqual(left.solution, right.solution)
            XCTAssertEqual(left.choices, right.choices)
        }
    }

    func testPlayerNameStartsOutBlank() {
        XCTAssertEqual(QuizProgress.fresh.playerName, "")
        XCTAssertEqual(QuizCopy.greeting(name: ""), "Ready to play?")
        XCTAssertEqual(QuizCopy.greeting(name: "  Sam "), "Hi, Sam!")
        XCTAssertEqual(
            WordProblems.names,
            ["Alex", "Jordan", "Maya", "Noah", "Priya", "Luis", "Sam", "Riley"]
        )
        for text in QuizCopy.fixedStrings {
            XCTAssertFalse(text.localizedCaseInsensitiveContains("wrong"))
            XCTAssertFalse(text.localizedCaseInsensitiveContains("fail"))
            XCTAssertFalse(text.localizedCaseInsensitiveContains("http"))
        }
    }

    private func assertSound(_ question: GeneratedQuestion) {
        XCTAssertEqual(question.level, min(max(question.level, 1), QuizRules.maxLevel))
        XCTAssertFalse(question.prompt.isEmpty)
        XCTAssertFalse(question.hint.isEmpty)
        XCTAssertFalse(question.solution.isEmpty)
        XCTAssertFalse(question.prompt.localizedCaseInsensitiveContains("http"))
        XCTAssertFalse(question.hint.localizedCaseInsensitiveContains("http"))
        XCTAssertFalse(question.solution.localizedCaseInsensitiveContains("wrong"))
        XCTAssertFalse(question.solution.localizedCaseInsensitiveContains("http"))
        XCTAssertEqual(question.answer, expected(question.audit))
        for token in question.answer.hiddenTokens {
            XCTAssertFalse(NumericText.contains(question.hint, answer: token), question.hint)
            XCTAssertTrue(
                NumericText.contains(question.solution, answer: token) || question.solution.contains(token),
                question.solution
            )
        }
        switch question.answer {
        case .integer:
            XCTAssertEqual(question.entry, .wholeNumber)
            XCTAssertTrue(question.choices.isEmpty)
        case .fraction:
            XCTAssertEqual(question.entry, .fraction)
        case .choice(let text):
            XCTAssertEqual(question.entry, .choices)
            XCTAssertEqual(question.choices.filter { $0 == text }.count, 1)
        }
        let packaged = question.question(id: UUID())
        XCTAssertTrue(Grader.isCorrect(question: packaged, response: Grader.canonicalResponse(for: packaged)))
        XCTAssertFalse(Grader.isCorrect(question: packaged, response: "nope"))
        assertLevelShape(question)
    }

    private func assertLevelShape(_ question: GeneratedQuestion) {
        switch question.audit {
        case .addition(let left, let right):
            XCTAssertGreaterThanOrEqual(left + right, 0)
            switch question.level {
            case 1:
                XCTAssertLessThanOrEqual(left + right, 10)
                XCTAssertLessThanOrEqual(max(left, right), 10)
            case 2:
                XCTAssertGreaterThanOrEqual(left + right, 11)
                XCTAssertLessThanOrEqual(max(left, right), 9)
            case 3:
                XCTAssertGreaterThanOrEqual(min(left, right), 10)
                XCTAssertLessThan(left % 10 + right % 10, 10)
            case 4:
                XCTAssertGreaterThanOrEqual(min(left, right), 10)
                XCTAssertLessThan(max(left, right), 100)
                XCTAssertGreaterThanOrEqual(left % 10 + right % 10, 10)
            default:
                XCTAssertGreaterThanOrEqual(min(left, right), 100)
                XCTAssertGreaterThanOrEqual(left % 10 + right % 10, 10)
            }
        case .subtraction(let left, let right):
            XCTAssertGreaterThanOrEqual(left - right, 0)
            switch question.level {
            case 1:
                XCTAssertLessThanOrEqual(left, 10)
            case 2:
                XCTAssertGreaterThanOrEqual(left, 11)
                XCTAssertLessThanOrEqual(left, 18)
                XCTAssertGreaterThan(right, left % 10)
            case 3:
                XCTAssertGreaterThanOrEqual(min(left, right), 10)
                XCTAssertLessThanOrEqual(right % 10, left % 10)
            case 4:
                XCTAssertGreaterThanOrEqual(min(left, right), 10)
                XCTAssertLessThan(max(left, right), 100)
                XCTAssertGreaterThan(right % 10, left % 10)
            default:
                XCTAssertGreaterThanOrEqual(left, 100)
                XCTAssertGreaterThan(right % 10, left % 10)
            }
        case .multiplication(let left, let right):
            XCTAssertGreaterThanOrEqual(left, 0)
            XCTAssertGreaterThanOrEqual(right, 0)
            XCTAssertLessThanOrEqual(max(left, right), 12)
            if question.level == 1 {
                let focus: Set<Int> = [0, 1, 2, 5, 10]
                XCTAssertTrue(focus.contains(left) || focus.contains(right))
            }
            if question.level == 5 {
                XCTAssertGreaterThanOrEqual(min(left, right), 2)
            }
        case .division(let dividend, let divisor):
            XCTAssertGreaterThanOrEqual(divisor, 1)
            XCTAssertLessThanOrEqual(divisor, 12)
            XCTAssertEqual(dividend % divisor, 0)
            let quotient = dividend / divisor
            XCTAssertGreaterThanOrEqual(quotient, 1)
            XCTAssertLessThanOrEqual(quotient, 12)
            if question.level == 5 {
                XCTAssertGreaterThanOrEqual(min(divisor, quotient), 2)
            }
        case .shaded(let numerator, let denominator):
            XCTAssertGreaterThan(numerator, 0)
            XCTAssertLessThan(numerator, denominator)
            XCTAssertLessThanOrEqual(denominator, 12)
        case .greater(let left, let right):
            XCTAssertFalse(left.isEquivalent(to: right))
            XCTAssertGreaterThan(left.denominator, 0)
            XCTAssertGreaterThan(right.denominator, 0)
        case .simplify(let from, let to):
            XCTAssertFalse(from.isSimplified)
            XCTAssertTrue(to.isSimplified)
            XCTAssertTrue(from.isEquivalent(to: to))
        case .fractionAdd(let left, let right), .fractionSubtract(let left, let right):
            XCTAssertEqual(left.denominator, right.denominator)
            XCTAssertGreaterThan(left.denominator, 0)
            if case .fractionSubtract = question.audit {
                XCTAssertGreaterThan(left.numerator, right.numerator)
            } else {
                XCTAssertLessThanOrEqual(left.numerator + right.numerator, left.denominator)
            }
        case .fractionOf(let numerator, let denominator, let whole):
            XCTAssertEqual(whole % denominator, 0)
            XCTAssertGreaterThan(numerator, 0)
            XCTAssertLessThan(numerator, denominator)
            XCTAssertFalse(NumericText.contains(question.prompt, answer: String(numerator * whole / denominator)))
        case .digitValue(let number, let place), .digitIdentity(let number, let place):
            let digit = (number / place) % 10
            XCTAssertGreaterThan(digit, 0)
            XCTAssertEqual(countDigits(digit, in: number), 1)
            if question.level == 1 { XCTAssertLessThan(number, 100) }
            if question.level == 2 { XCTAssertGreaterThanOrEqual(number, 100); XCTAssertLessThan(number, 1000) }
            if question.level == 5 { XCTAssertGreaterThanOrEqual(number, 1000) }
        case .expanded(let hundreds, let tens, let ones):
            XCTAssertGreaterThan(hundreds, 0)
            XCTAssertTrue(tens > 0 || ones > 0)
        case .compare(let left, let right):
            XCTAssertNotEqual(left, right)
        case .round(let number, let place):
            XCTAssertNotEqual(number % place, 0)
            XCTAssertTrue(place == 10 || place == 100)
        case .word(let answer, let shown):
            XCTAssertGreaterThan(answer, 0)
            XCTAssertFalse(NumericText.contains(question.prompt, answer: String(answer)))
            for number in shown {
                XCTAssertTrue(NumericText.contains(question.prompt, answer: String(number)))
            }
        case .wordFraction(let numerator, let denominator, let shown):
            XCTAssertGreaterThan(numerator, 0)
            XCTAssertLessThan(numerator, denominator)
            XCTAssertFalse(NumericText.contains(question.prompt, answer: Fraction(numerator, denominator).display))
            for number in shown {
                XCTAssertTrue(NumericText.contains(question.prompt, answer: String(number)))
            }
        }
    }

    private func expected(_ audit: ProblemAudit) -> AnswerKey {
        switch audit {
        case .addition(let left, let right):
            return .integer(left + right)
        case .subtraction(let left, let right):
            return .integer(left - right)
        case .multiplication(let left, let right):
            return .integer(left * right)
        case .division(let dividend, let divisor):
            return .integer(dividend / divisor)
        case .shaded(let numerator, let denominator):
            return .fraction(Fraction(numerator, denominator), acceptEquivalent: true)
        case .greater(let left, let right):
            let leftWins = left.numerator * right.denominator > right.numerator * left.denominator
            return .choice((leftWins ? left : right).display)
        case .simplify(_, let to):
            return .fraction(to, acceptEquivalent: false)
        case .fractionAdd(let left, let right):
            return .fraction(Fraction(left.numerator + right.numerator, left.denominator), acceptEquivalent: true)
        case .fractionSubtract(let left, let right):
            return .fraction(Fraction(left.numerator - right.numerator, left.denominator), acceptEquivalent: true)
        case .fractionOf(let numerator, let denominator, let whole):
            return .integer(numerator * whole / denominator)
        case .digitValue(let number, let place):
            return .integer(((number / place) % 10) * place)
        case .digitIdentity(let number, let place):
            return .integer((number / place) % 10)
        case .expanded(let hundreds, let tens, let ones):
            return .integer(hundreds * 100 + tens * 10 + ones)
        case .compare(let left, let right):
            return .choice(String(max(left, right)))
        case .round(let number, let place):
            let remainder = number % place
            let down = number - remainder
            return .integer(remainder * 2 >= place ? down + place : down)
        case .word(let answer, _):
            return .integer(answer)
        case .wordFraction(let numerator, let denominator, _):
            return .fraction(Fraction(numerator, denominator), acceptEquivalent: true)
        }
    }

    private func countDigits(_ digit: Int, in number: Int) -> Int {
        var rest = number
        var count = 0
        while rest > 0 {
            if rest % 10 == digit { count += 1 }
            rest /= 10
        }
        return count
    }

    private func topicIndex(_ topic: Topic) -> Int {
        Topic.allCases.firstIndex(of: topic) ?? 0
    }
}

final class ProgressStoreTests: XCTestCase {
    func testSupportDirectoryLivesBesideTheLauncherData() {
        let home = URL(fileURLWithPath: "/Users/sam", isDirectory: true)
        XCTAssertEqual(
            MathQuizSupport.directory(home: home).path,
            "/Users/sam/Library/Application Support/MathQuiz"
        )
        XCTAssertEqual(MathQuizRelease.bundleID, "com.kidscomputer.mathquiz")
        XCTAssertEqual(MathQuizRelease.applicationPath, "/Applications/Math Quiz.app")
    }

    func testSaveAndLoadRoundTrip() throws {
        let store = try makeStore()
        var progress = QuizProgress.fresh
        progress.playerName = "Sam"
        progress.stars = 12
        progress.bestStreak = 4
        progress.setSkill(Skill(level: 3, correctStreak: 1, missStreak: 0), for: .fractions)
        progress.badges = [.firstStar, .streak3]
        progress.topicCorrect[.addition] = 2
        try store.save(progress)
        let loaded = store.load()
        XCTAssertEqual(loaded.playerName, "Sam")
        XCTAssertEqual(loaded.stars, 12)
        XCTAssertEqual(loaded.skill(for: .fractions).level, 3)
        XCTAssertEqual(loaded.skill(for: .division).level, 1)
        XCTAssertEqual(loaded.badges, [.firstStar, .streak3])
        XCTAssertEqual(loaded.correctCount(for: .addition), 2)
        let text = try String(contentsOf: store.fileURL, encoding: .utf8)
        XCTAssertTrue(text.contains("\"version\" : 1"))
        XCTAssertFalse(text.localizedCaseInsensitiveContains("http"))
    }

    func testPartialAndUnknownDataStillOpens() throws {
        let store = try makeStore()
        let json = """
        {"version":1,"progress":{"stars":4,"playerName":"  Sam\\n","badges":["first-star","not-real"],"skills":{"addition":{"level":0}}}}
        """
        try json.data(using: .utf8)!.write(to: store.fileURL)
        let loaded = store.load()
        XCTAssertEqual(loaded.playerName, "Sam")
        XCTAssertEqual(loaded.stars, 4)
        XCTAssertEqual(loaded.badges, [.firstStar])
        XCTAssertEqual(loaded.skill(for: .addition).level, 1)
        XCTAssertEqual(loaded.skill(for: .wordProblems).level, 1)
    }

    func testCorruptFileIsSetAside() throws {
        let store = try makeStore()
        try "not json".data(using: .utf8)!.write(to: store.fileURL)
        let loaded = store.load()
        XCTAssertEqual(loaded, .fresh)
        XCTAssertFalse(store.fileManager.fileExists(atPath: store.fileURL.path))
        let backup = try String(contentsOf: store.backupURL, encoding: .utf8)
        XCTAssertEqual(backup, "not json")
    }

    func testPlayerNameIsOptionalAndPlain() {
        XCTAssertEqual(PlayerName.cleaned("  \n"), "")
        XCTAssertEqual(PlayerName.cleaned("Maya-Jane"), "Maya-Jane")
        XCTAssertEqual(PlayerName.cleaned("O'Neil!!"), "O'Neil")
        XCTAssertEqual(PlayerName.cleaned(String(repeating: "A", count: 40)).count, PlayerName.maxLength)
        XCTAssertEqual(QuizCopy.encouragement(correct: 10, total: 10).contains("wonderful"), true)
        XCTAssertEqual(QuizCopy.encouragement(correct: 0, total: 10).contains("breath"), true)
        XCTAssertTrue(QuizCopy.missed(solution: "1 + 1 = 2.").hasPrefix("Not quite."))
        XCTAssertTrue(QuizCopy.timedOut(solution: "1 + 1 = 2.").hasPrefix("Time's up."))
        XCTAssertFalse(QuizCopy.missed(solution: "1 + 1 = 2.").localizedCaseInsensitiveContains("wrong"))
        XCTAssertEqual(BadgeRules.nextGoal(in: .fresh), .firstStar)
        var done = QuizProgress.fresh
        done.badges = Badge.allCases
        XCTAssertNil(BadgeRules.nextGoal(in: done))
        let again = BadgeRules.award(into: &done)
        XCTAssertTrue(again.isEmpty)
        XCTAssertEqual(done.badges.count, Badge.allCases.count)
    }

    func testBundleAndBuildHook() throws {
        let packageRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let plist = try String(contentsOf: packageRoot.appendingPathComponent("Packaging/Info.plist"), encoding: .utf8)
        XCTAssertTrue(plist.contains("<string>\(MathQuizRelease.bundleID)</string>"))
        XCTAssertTrue(plist.contains("<string>MathQuiz</string>"))
        XCTAssertTrue(plist.contains("<string>14.0</string>"))
        XCTAssertTrue(plist.contains("<string>1.0.0</string>"))
        XCTAssertTrue(plist.contains("<string>AppIcon</string>"))
        XCTAssertTrue(plist.contains("<false/>"))
        let build = try String(contentsOf: packageRoot.appendingPathComponent("build.sh"), encoding: .utf8)
        XCTAssertTrue(build.contains("Math Quiz.app"))
        XCTAssertTrue(build.contains(MathQuizRelease.bundleID))
        XCTAssertTrue(build.contains("--arch arm64"))
        XCTAssertTrue(build.contains("--arch x86_64"))
        XCTAssertTrue(build.contains("Packaging/MathQuiz.entitlements"))
        let entitlements = try String(
            contentsOf: packageRoot.appendingPathComponent("Packaging/MathQuiz.entitlements"),
            encoding: .utf8
        )
        XCTAssertTrue(entitlements.contains("com.apple.security.app-sandbox"))
        XCTAssertFalse(entitlements.contains("com.apple.security.network.client"))
        XCTAssertFalse(entitlements.contains("com.apple.security.network.server"))
        let privacy = try String(
            contentsOf: packageRoot.appendingPathComponent("Packaging/PrivacyInfo.xcprivacy"),
            encoding: .utf8
        )
        XCTAssertTrue(privacy.contains("NSPrivacyTracking"))
        XCTAssertTrue(privacy.contains("<key>NSPrivacyCollectedDataTypes</key>"))
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: packageRoot
                    .appendingPathComponent("Packaging/Assets.xcassets/AppIcon.appiconset/Contents.json")
                    .path
            )
        )
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: packageRoot
                    .appendingPathComponent("Packaging/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png")
                    .path
            )
        )
        let readme = try String(contentsOf: packageRoot.appendingPathComponent("README.md"), encoding: .utf8)
        XCTAssertTrue(readme.contains("https://github.com/matjns/kids-math-quiz/releases"))
        XCTAssertTrue(readme.contains(MathQuizRelease.bundleID))
        let macReadme = try String(contentsOf: packageRoot.appendingPathComponent("README-mac.txt"), encoding: .utf8)
        XCTAssertTrue(macReadme.contains("xattr -cr"))
        XCTAssertTrue(macReadme.contains("Open Anyway"))
        let workflow = try String(
            contentsOf: packageRoot.appendingPathComponent(".github/workflows/macos.yml"),
            encoding: .utf8
        )
        XCTAssertTrue(workflow.contains("macos-latest"))
        XCTAssertTrue(workflow.contains("MathQuiz-mac-universal.zip"))
        let license = try String(contentsOf: packageRoot.appendingPathComponent("LICENSE"), encoding: .utf8)
        XCTAssertTrue(license.contains("2026"))
        XCTAssertTrue(license.contains("matjns"))
        XCTAssertTrue(
            FileManager.default.fileExists(
                atPath: packageRoot.appendingPathComponent("docs/APP_STORE.md").path
            )
        )
    }

    private func makeStore() throws -> ProgressStore {
        let root = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("mathquiz-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }
        return ProgressStore(directory: root)
    }
}
