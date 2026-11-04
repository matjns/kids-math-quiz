import Foundation

public enum MathQuizRelease {
    public static let version = "1.0.0"
    public static let bundleID = "com.kidscomputer.mathquiz"
    public static let displayName = "Math Quiz"
    public static let supportFolderName = "MathQuiz"
    public static let progressFileName = "progress.json"
    public static let applicationPath = "/Applications/Math Quiz.app"
}

public enum MathQuizSupport {
    public static func directory(home: URL) -> URL {
        home.appendingPathComponent(
            "Library/Application Support/\(MathQuizRelease.supportFolderName)",
            isDirectory: true
        )
    }
}

public enum QuizRules {
    /// A round is short on purpose. Ten questions, then a break.
    public static let questionsPerRound = 10
    /// Lightning is optional. Everyday play has no timer.
    public static let lightningSeconds = 20
    public static let maxLevel = 5
    /// Three correct answers in a row at the current level move that topic up.
    public static let streakToLevelUp = 3
    /// Two misses in a row ease that topic down one level. One miss does not.
    public static let missesToLevelDown = 2
    public static let maxOfOneTopic = 3
}
