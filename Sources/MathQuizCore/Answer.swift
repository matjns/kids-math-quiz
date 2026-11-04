import Foundation

public enum AnswerKey: Equatable {
    case integer(Int)
    /// `acceptEquivalent` is true for "what fraction is this?" and arithmetic.
    /// It is false when the question asks for simplest form.
    case fraction(Fraction, acceptEquivalent: Bool)
    case choice(String)

    public var hiddenTokens: [String] {
        switch self {
        case .integer(let value):
            return [String(value)]
        case .fraction(let fraction, _):
            return Array(Set([fraction.display, fraction.simplified.display]))
        case .choice(let text):
            return [text]
        }
    }
}

public struct Question: Equatable, Identifiable {
    public var id: UUID
    public var topic: Topic
    public var level: Int
    public var prompt: String
    public var entry: EntryStyle
    public var choices: [String]
    public var answer: AnswerKey
    public var hint: String
    public var solution: String

    public init(
        id: UUID,
        topic: Topic,
        level: Int,
        prompt: String,
        entry: EntryStyle,
        choices: [String],
        answer: AnswerKey,
        hint: String,
        solution: String
    ) {
        self.id = id
        self.topic = topic
        self.level = level
        self.prompt = prompt
        self.entry = entry
        self.choices = choices
        self.answer = answer
        self.hint = hint
        self.solution = solution
    }
}
