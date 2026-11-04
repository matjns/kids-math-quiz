import Foundation

public enum PlayerName {
    public static let maxLength = 20

    public static func cleaned(_ raw: String) -> String {
        let flattened = raw
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        var kept = ""
        for character in flattened {
            if character.isLetter || character.isNumber || character == " " || character == "'" || character == "’" || character == "-" {
                kept.append(character)
            }
        }
        let collapsed = kept.split(whereSeparator: { $0 == " " }).joined(separator: " ")
        return String(collapsed.prefix(maxLength))
    }
}

public enum QuizCopy {
    public static let practiceTitle = "Play a round"
    public static let practiceDetail = "10 questions, no timer"
    public static let lightningTitle = "Lightning round"
    public static let lightningDetail = "10 questions, 20 seconds each. Hit Check before the bar runs out."
    public static let progressTitle = "See your progress"
    public static let nameButton = "Your name"
    public static let nameTitle = "What should we call you?"
    public static let nameNote = "This is optional. Leave it blank and no name is shown."
    public static let saveName = "Save"
    public static let clearName = "No name"
    public static let stopTitle = "Go home?"
    public static let stopMessage = "You keep the stars you already earned."
    public static let keepPlaying = "Keep playing"
    public static let goHome = "Go home"
    public static let stopButton = "Stop"
    public static let check = "Check"
    public static let next = "Next"
    public static let finish = "See how you did"
    public static let playAgain = "Play again"
    public static let home = "Home"
    public static let levelUpNote = "This topic is stepping up a little."
    public static let placeholder = "Your answer"
    public static let emptyProgress = "Every topic starts at Warm-up. A round will fill this in."

    public static func greeting(name: String) -> String {
        let cleaned = PlayerName.cleaned(name)
        if cleaned.isEmpty {
            return "Ready to play?"
        }
        return "Hi, \(cleaned)!"
    }

    public static func correct(solution: String, streak: Int) -> String {
        if streak >= 10 {
            return "Incredible. \(solution)"
        }
        if streak >= 5 {
            return "You're on a roll. \(solution)"
        }
        if streak >= 3 {
            return "Yes! \(solution)"
        }
        return "You got it. \(solution)"
    }

    public static func missed(solution: String) -> String {
        "Not quite. \(solution)"
    }

    public static func timedOut(solution: String) -> String {
        "Time's up. \(solution)"
    }

    public static func starsEarned(_ count: Int) -> String? {
        switch count {
        case 1:
            return "1 star"
        case 2...:
            return "\(count) stars"
        default:
            return nil
        }
    }

    public static func encouragement(correct: Int, total: Int) -> String {
        guard total > 0 else { return "Ready for another round?" }
        let score = correct * 10 / total
        switch score {
        case 10:
            return "A perfect round. That was wonderful."
        case 8...9:
            return "So close to perfect. Look at you go."
        case 6...7:
            return "Nice round. You figured out a lot of these."
        case 4...5:
            return "You got some tricky ones. Every star counts."
        case 1...3:
            return "That set was tough. The next one can feel a little friendlier."
        default:
            return "Tough round. Take a breath. The next set eases up with you."
        }
    }

    public static func questionProgress(index: Int, total: Int) -> String {
        "Question \(index) of \(total)"
    }

    public static func outOf(correct: Int, total: Int) -> String {
        "\(correct) out of \(total)"
    }

    public static func roundStars(_ count: Int) -> String {
        count == 1 ? "You earned 1 star." : "You earned \(count) stars."
    }

    public static func altogether(_ count: Int) -> String {
        count == 1 ? "1 star altogether." : "\(count) stars altogether."
    }

    public static var fixedStrings: [String] {
        [
            practiceTitle, practiceDetail, lightningTitle, lightningDetail,
            progressTitle, nameButton, nameTitle, nameNote, saveName, clearName,
            stopTitle, stopMessage, keepPlaying, goHome, stopButton, check, next,
            finish, playAgain, home, levelUpNote, placeholder, emptyProgress,
        ]
    }
}
