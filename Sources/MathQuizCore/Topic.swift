import Foundation

public enum Topic: String, Codable, CaseIterable, Equatable, Hashable {
    case addition
    case subtraction
    case multiplication
    case division
    case fractions
    case placeValue
    case wordProblems

    public var title: String {
        switch self {
        case .addition: return "Addition"
        case .subtraction: return "Subtraction"
        case .multiplication: return "Multiplication"
        case .division: return "Division"
        case .fractions: return "Fractions"
        case .placeValue: return "Place value"
        case .wordProblems: return "Word problems"
        }
    }

    public var symbolName: String {
        switch self {
        case .addition: return "plus"
        case .subtraction: return "minus"
        case .multiplication: return "multiply"
        case .division: return "divide"
        case .fractions: return "circle.lefthalf.filled"
        case .placeValue: return "textformat.123"
        case .wordProblems: return "text.book.closed"
        }
    }
}

public enum EntryStyle: String, Codable, Equatable {
    case wholeNumber
    case fraction
    case choices
}

public enum SkillLevelName {
    public static func title(for level: Int) -> String {
        switch min(max(level, 1), QuizRules.maxLevel) {
        case 1: return "Warm-up"
        case 2: return "Growing"
        case 3: return "Steady"
        case 4: return "Strong"
        default: return "Super"
        }
    }
}
