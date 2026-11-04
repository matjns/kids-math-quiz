import Foundation

public enum EntryCheck {
    public static func isReady(_ raw: String, style: EntryStyle) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        switch style {
        case .wholeNumber:
            return Grader.integer(in: trimmed) != nil
        case .fraction:
            return Grader.fraction(in: trimmed) != nil
        case .choices:
            return !trimmed.isEmpty
        }
    }
}

public enum Grader {
    public static func isCorrect(question: Question, response: String) -> Bool {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        switch question.answer {
        case .integer(let value):
            guard let parsed = integer(in: trimmed) else { return false }
            return parsed == value
        case .fraction(let expected, let acceptEquivalent):
            guard let parsed = fraction(in: trimmed) else { return false }
            if acceptEquivalent {
                return parsed.isEquivalent(to: expected)
            }
            return parsed.isSimplified && parsed.simplified == expected.simplified
        case .choice(let expected):
            return canonicalChoice(trimmed) == canonicalChoice(expected)
        }
    }

    public static func canonicalResponse(for question: Question) -> String {
        switch question.answer {
        case .integer(let value):
            return String(value)
        case .fraction(let fraction, _):
            return fraction.display
        case .choice(let text):
            return text
        }
    }

    static func integer(in raw: String) -> Int? {
        var digits = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if digits.hasPrefix("+") {
            digits.removeFirst()
        }
        guard !digits.isEmpty, digits.allSatisfy(\.isNumber) else { return nil }
        return Int(digits)
    }

    static func fraction(in raw: String) -> Fraction? {
        let trimmed = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "⁄", with: "/")
        let parts = trimmed.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        guard let numerator = integer(in: String(parts[0])),
              let denominator = integer(in: String(parts[1])),
              denominator != 0 else {
            return nil
        }
        return Fraction(numerator, denominator)
    }

    private static func canonicalChoice(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "⁄", with: "/")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .replacingOccurrences(of: " / ", with: "/")
            .lowercased()
    }
}
