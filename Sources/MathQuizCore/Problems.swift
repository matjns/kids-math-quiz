enum AdditionProblems {
    static func make(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        let left: Int
        let right: Int
        switch level {
        case 1:
            left = rng.int(0...10)
            right = rng.int(0...(10 - left))
        case 2:
            left = rng.int(2...9)
            right = rng.int(max(2, 11 - left)...9)
        case 3:
            let leftTens = rng.int(1...6)
            let leftOnes = rng.int(0...8)
            let rightTens = rng.int(1...(7 - leftTens))
            let rightOnes = rng.int(0...(9 - leftOnes))
            left = leftTens * 10 + leftOnes
            right = rightTens * 10 + rightOnes
        case 4:
            let leftOnes = rng.int(2...9)
            let rightOnes = rng.int((10 - leftOnes)...9)
            left = rng.int(1...8) * 10 + leftOnes
            right = rng.int(1...8) * 10 + rightOnes
        default:
            let leftOnes = rng.int(2...9)
            let rightOnes = rng.int((10 - leftOnes)...9)
            left = rng.int(1...7) * 100 + rng.int(0...9) * 10 + leftOnes
            right = rng.int(1...7) * 100 + rng.int(0...8) * 10 + rightOnes
        }
        let sum = left + right
        let onesSum = (left % 10) + (right % 10)
        let preferred: String
        if left < 10, right < 10 {
            preferred = "Start at the bigger number and count on."
        } else if onesSum >= 10 {
            preferred = "Add the ones: \(left % 10) + \(right % 10) = \(onesSum). Write the ones digit and carry a ten."
        } else {
            preferred = "Add the ones, then the tens. The ones stay under ten, so there is nothing to carry."
        }
        return pack(
            topic: .addition,
            level: level,
            prompt: "What is \(left) + \(right)?",
            answer: .integer(sum),
            hint: preferred,
            fallback: "Add the ones, then the tens.",
            solution: "\(left) + \(right) = \(sum).",
            audit: .addition(left, right)
        )
    }
}

enum SubtractionProblems {
    static func make(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        let left: Int
        let right: Int
        switch level {
        case 1:
            left = rng.int(1...10)
            right = rng.int(0...left)
        case 2:
            left = rng.int(11...18)
            right = rng.int((left % 10 + 1)...9)
        case 3:
            let leftTens = rng.int(3...9)
            let leftOnes = rng.int(1...9)
            left = leftTens * 10 + leftOnes
            right = rng.int(1...(leftTens - 1)) * 10 + rng.int(0...leftOnes)
        case 4:
            let leftTens = rng.int(3...9)
            let leftOnes = rng.int(0...8)
            left = leftTens * 10 + leftOnes
            right = rng.int(1...(leftTens - 1)) * 10 + rng.int((leftOnes + 1)...9)
        default:
            if rng.bool() {
                let hundreds = rng.int(3...9)
                let ones = rng.int(0...8)
                left = hundreds * 100 + ones
                right = rng.int(1...(hundreds - 1)) * 100 + rng.int(1...9) * 10 + rng.int((ones + 1)...9)
            } else {
                let hundreds = rng.int(3...9)
                let ones = rng.int(0...8)
                left = hundreds * 100 + rng.int(0...9) * 10 + ones
                right = rng.int(1...(hundreds - 1)) * 100 + rng.int(0...9) * 10 + rng.int((ones + 1)...9)
            }
        }
        let difference = left - right
        let preferred = right % 10 > left % 10
            ? "The ones are too small to subtract. Borrow a ten, then subtract the ones."
            : "Subtract the ones, then the tens. Count up if that feels easier."
        return pack(
            topic: .subtraction,
            level: level,
            prompt: "What is \(left) − \(right)?",
            answer: .integer(difference),
            hint: preferred,
            fallback: "Count up from the smaller number, or borrow a ten if the ones are too small.",
            solution: "\(left) − \(right) = \(difference).",
            audit: .subtraction(left, right)
        )
    }
}

enum MultiplicationProblems {
    static func make(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        let pair = factors(level: level, rng: &rng)
        let product = pair.0 * pair.1
        return pack(
            topic: .multiplication,
            level: level,
            prompt: "What is \(pair.0) × \(pair.1)?",
            answer: .integer(product),
            hint: preferredHint(pair.0, pair.1),
            fallback: "Think of equal groups.",
            solution: "\(pair.0) × \(pair.1) = \(product).",
            audit: .multiplication(pair.0, pair.1)
        )
    }

    private static func factors(level: Int, rng: inout SplitMix64) -> (Int, Int) {
        let pair: (Int, Int)
        switch level {
        case 1:
            pair = (rng.pick([0, 1, 2, 5, 10]), rng.int(0...12))
        case 2:
            pair = (rng.pick([3, 4]), rng.int(1...12))
        case 3:
            pair = (rng.pick([6, 7, 8]), rng.int(1...12))
        case 4:
            pair = (rng.pick([9, 11, 12]), rng.int(1...12))
        default:
            pair = (rng.int(2...12), rng.int(2...12))
        }
        return rng.bool() ? pair : (pair.1, pair.0)
    }

    private static func preferredHint(_ left: Int, _ right: Int) -> String {
        if left == 0 || right == 0 {
            return "If either factor is zero, the product is zero."
        }
        if left == 1 || right == 1 {
            return "Multiplying by one leaves the other number as it is."
        }
        if left == 10 || right == 10 {
            return "Multiplying by ten puts a zero on the end of the other number."
        }
        if left == 2 || right == 2 {
            return "Multiplying by two is doubling the other number."
        }
        if left == 5 || right == 5 {
            return "Multiplying by five is half of multiplying by ten."
        }
        if left == 9 || right == 9 {
            return "Multiplying by nine is one group less than multiplying by ten."
        }
        if left == 11 || right == 11 {
            return "Multiplying by eleven is multiplying by ten, then adding one more group."
        }
        return "\(left) × \(right) means \(left) groups of \(right)."
    }
}

enum DivisionProblems {
    static func make(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        let pair = factors(level: level, rng: &rng)
        let dividend = pair.divisor * pair.quotient
        return pack(
            topic: .division,
            level: level,
            prompt: "What is \(dividend) ÷ \(pair.divisor)?",
            answer: .integer(pair.quotient),
            hint: "\(pair.divisor) times what number equals \(dividend)?",
            fallback: "Think of the multiplication fact that uses these numbers.",
            solution: "\(dividend) ÷ \(pair.divisor) = \(pair.quotient).",
            audit: .division(dividend: dividend, divisor: pair.divisor)
        )
    }

    private static func factors(level: Int, rng: inout SplitMix64) -> (divisor: Int, quotient: Int) {
        let focus: (Int, Int)
        switch level {
        case 1:
            focus = (rng.pick([1, 2, 5, 10]), rng.int(1...12))
        case 2:
            focus = (rng.pick([3, 4]), rng.int(1...12))
        case 3:
            focus = (rng.pick([6, 7, 8]), rng.int(1...12))
        case 4:
            focus = (rng.pick([9, 11, 12]), rng.int(1...12))
        default:
            focus = (rng.int(2...12), rng.int(2...12))
        }
        if rng.bool() {
            return (divisor: focus.0, quotient: focus.1)
        }
        return (divisor: focus.1, quotient: focus.0)
    }
}

enum FractionProblems {
    static func make(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        switch level {
        case 1:
            return shaded(rng: &rng, level: level)
        case 2:
            return compare(rng: &rng, level: level)
        case 3:
            return simplify(rng: &rng, level: level)
        case 4:
            return rng.bool() ? add(rng: &rng, level: level) : subtract(rng: &rng, level: level)
        default:
            return ofAWhole(rng: &rng, level: level)
        }
    }

    private static func shaded(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let denominator = rng.pick([2, 3, 4, 5, 6, 8, 10, 12])
        let numerator = rng.int(1...(denominator - 1))
        let fraction = Fraction(numerator, denominator)
        return pack(
            topic: .fractions,
            level: level,
            prompt: "A shape is split into \(denominator) equal parts. \(numerator) of them are shaded. What fraction is shaded?",
            answer: .fraction(fraction, acceptEquivalent: true),
            hint: "The bottom number counts the equal parts. The top number counts the shaded parts.",
            fallback: "The bottom number counts the equal parts. The top number counts the shaded parts.",
            solution: fractionSentence(numerator, denominator, fraction),
            audit: .shaded(numerator: numerator, denominator: denominator)
        )
    }

    private static func compare(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let left: Fraction
        let right: Fraction
        let hint: String
        if rng.bool() {
            let denominator = rng.int(2...12)
            let first = rng.int(1...(denominator - 1))
            var second = rng.int(1...(denominator - 1))
            if first == second {
                second = first == denominator - 1 ? first - 1 : first + 1
            }
            left = Fraction(first, denominator)
            right = Fraction(second, denominator)
            hint = "The pieces are the same size, so the larger top number is greater."
        } else {
            let first = rng.int(2...12)
            var second = rng.int(2...12)
            if first == second {
                second = first == 12 ? 2 : first + 1
            }
            left = Fraction(1, first)
            right = Fraction(1, second)
            hint = "Both tops are one. The smaller bottom number is the bigger piece."
        }
        let winner = left.numerator * right.denominator >= right.numerator * left.denominator ? left : right
        let loser = winner == left ? right : left
        let choices = shuffled([left.display, right.display], rng: &rng)
        return pack(
            topic: .fractions,
            level: level,
            prompt: "Which fraction is greater?",
            answer: .choice(winner.display),
            hint: hint,
            fallback: "Compare the size of the pieces, not just the size of the numbers.",
            solution: "\(winner.display) is greater than \(loser.display).",
            choices: choices,
            audit: .greater(left, right)
        )
    }

    private static func simplify(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let options = unsimplifiedPairs()
        let pair = rng.pick(options)
        return pack(
            topic: .fractions,
            level: level,
            prompt: "Write \(pair.from.display) in simplest form.",
            answer: .fraction(pair.to, acceptEquivalent: false),
            hint: "Divide the top and the bottom by the same number until you cannot.",
            fallback: "Divide the top and the bottom by the same number until you cannot.",
            solution: "\(pair.from.display) in simplest form is \(pair.to.display).",
            audit: .simplify(from: pair.from, to: pair.to)
        )
    }

    private static func unsimplifiedPairs() -> [(from: Fraction, to: Fraction)] {
        let bases = [(1, 2), (1, 3), (2, 3), (1, 4), (3, 4), (1, 5), (2, 5), (3, 5), (4, 5), (1, 6), (5, 6)]
        var pairs: [(Fraction, Fraction)] = []
        for (numerator, denominator) in bases {
            for multiplier in 2...6 {
                let scaledDenominator = denominator * multiplier
                if scaledDenominator <= 12 {
                    pairs.append((Fraction(numerator * multiplier, scaledDenominator), Fraction(numerator, denominator)))
                }
            }
        }
        return pairs
    }

    private static func add(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let denominator = rng.pick([2, 3, 4, 5, 6, 8, 10, 12])
        let leftNumerator = rng.int(1...(denominator - 1))
        let rightNumerator = rng.int(1...(denominator - leftNumerator))
        let left = Fraction(leftNumerator, denominator)
        let right = Fraction(rightNumerator, denominator)
        let sum = Fraction(leftNumerator + rightNumerator, denominator)
        return pack(
            topic: .fractions,
            level: level,
            prompt: "What is \(left.display) + \(right.display)?",
            answer: .fraction(sum, acceptEquivalent: true),
            hint: "The bottoms match, so add the tops and keep the bottom.",
            fallback: "The bottoms match, so add the tops and keep the bottom.",
            solution: fractionSentence(left, "+", right, sum),
            audit: .fractionAdd(left, right)
        )
    }

    private static func subtract(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let denominator = rng.pick([2, 3, 4, 5, 6, 8, 10, 12])
        let leftNumerator = rng.int(2...denominator)
        let rightNumerator = rng.int(1...(leftNumerator - 1))
        let left = Fraction(leftNumerator, denominator)
        let right = Fraction(rightNumerator, denominator)
        let difference = Fraction(leftNumerator - rightNumerator, denominator)
        return pack(
            topic: .fractions,
            level: level,
            prompt: "What is \(left.display) − \(right.display)?",
            answer: .fraction(difference, acceptEquivalent: true),
            hint: "The bottoms match, so subtract the tops and keep the bottom.",
            fallback: "The bottoms match, so subtract the tops and keep the bottom.",
            solution: fractionSentence(left, "−", right, difference),
            audit: .fractionSubtract(left, right)
        )
    }

    private static func ofAWhole(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        for _ in 0..<20 {
            let denominator = rng.pick([2, 3, 4, 5, 6, 8, 10, 12])
            let numerator = rng.int(1...(denominator - 1))
            let groups = rng.int(2...4)
            let whole = denominator * groups
            let result = numerator * groups
            let prompt = "What is \(numerator)/\(denominator) of \(whole)?"
            if NumericText.contains(prompt, answer: String(result)) { continue }
            return pack(
                topic: .fractions,
                level: level,
                prompt: prompt,
                answer: .integer(result),
                hint: "Split the whole into the bottom number of equal groups, then take as many groups as the top number.",
                fallback: "Split the whole into equal groups, then take the number of groups the top asks for.",
                solution: "\(numerator)/\(denominator) of \(whole) is \(result).",
                audit: .fractionOf(numerator: numerator, denominator: denominator, whole: whole)
            )
        }
        return pack(
            topic: .fractions,
            level: level,
            prompt: "What is 1/4 of 12?",
            answer: .integer(3),
            hint: "Split the whole into the bottom number of equal groups, then take as many groups as the top number.",
            fallback: "Split the whole into equal groups, then take the number of groups the top asks for.",
            solution: "1/4 of 12 is 3.",
            audit: .fractionOf(numerator: 1, denominator: 4, whole: 12)
        )
    }

    private static func fractionSentence(_ numerator: Int, _ denominator: Int, _ fraction: Fraction) -> String {
        let simple = fraction.simplified
        if fraction.display == simple.display {
            return "\(numerator) out of \(denominator) equal parts is \(fraction.display)."
        }
        return "\(numerator) out of \(denominator) equal parts is \(fraction.display), which is \(simple.display)."
    }

    private static func fractionSentence(_ left: Fraction, _ op: String, _ right: Fraction, _ result: Fraction) -> String {
        let simple = result.simplified
        if result.display == simple.display {
            return "\(left.display) \(op) \(right.display) = \(result.display)."
        }
        return "\(left.display) \(op) \(right.display) = \(result.display), which is \(simple.display)."
    }
}

enum PlaceValueProblems {
    static func make(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        switch level {
        case 1:
            return digitQuestion(range: 10...99, places: [1, 10], level: level, rng: &rng)
        case 2:
            return digitQuestion(range: 100...999, places: [1, 10, 100], level: level, rng: &rng)
        case 3:
            return expanded(level: level, rng: &rng)
        case 4:
            return rng.bool() ? compare(level: level, rng: &rng) : round(numberRange: 21...989, place: 10, level: level, rng: &rng)
        default:
            if rng.bool() {
                return digitQuestion(range: 1000...9999, places: [1000, 1000, 100, 10], level: level, rng: &rng)
            }
            return round(numberRange: 120...9800, place: 100, level: level, rng: &rng)
        }
    }

    private static func digitQuestion(range: ClosedRange<Int>, places: [Int], level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        for _ in 0..<24 {
            let number = rng.int(range)
            let place = rng.pick(places)
            let digit = digit(of: number, place: place)
            if digit == 0 || countOf(digit, in: number) != 1 {
                continue
            }
            return digitQuestion(number: number, place: place, digit: digit, level: level, rng: &rng)
        }
        if range.upperBound >= 1000 {
            return digitQuestion(number: 7305, place: 1000, digit: 7, level: level, rng: &rng)
        }
        if range.upperBound >= 100 {
            return digitQuestion(number: 305, place: 100, digit: 3, level: level, rng: &rng)
        }
        return digitQuestion(number: 47, place: 10, digit: 4, level: level, rng: &rng)
    }

    private static func digitQuestion(number: Int, place: Int, digit: Int, level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        let name = placeName(place)
        if rng.bool() {
            let value = digit * place
            return pack(
                topic: .placeValue,
                level: level,
                prompt: "What is the value of the \(digit) in \(number)?",
                answer: .integer(value),
                hint: "The \(digit) is in the \(name) place.",
                fallback: "Find the place, then think how much one of that place is worth.",
                solution: "The \(digit) in \(number) is worth \(value).",
                audit: .digitValue(number: number, place: place)
            )
        }
        return pack(
            topic: .placeValue,
            level: level,
            prompt: "What digit is in the \(name) place of \(number)?",
            answer: .integer(digit),
            hint: "Count the places from the right: ones, tens, hundreds, thousands.",
            fallback: "Count the places from the right: ones, tens, hundreds, thousands.",
            solution: "The \(name) digit in \(number) is \(digit).",
            audit: .digitIdentity(number: number, place: place)
        )
    }

    private static func expanded(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        let hundreds = rng.int(1...9)
        let tens = rng.int(0...9)
        var ones = rng.int(0...9)
        if tens == 0, ones == 0 {
            ones = rng.int(1...9)
        }
        let number = hundreds * 100 + tens * 10 + ones
        return pack(
            topic: .placeValue,
            level: level,
            prompt: "What number is \(hundreds * 100) + \(tens * 10) + \(ones)?",
            answer: .integer(number),
            hint: "Add the hundreds, the tens, and the ones.",
            fallback: "Add the hundreds, the tens, and the ones.",
            solution: "\(hundreds * 100) + \(tens * 10) + \(ones) = \(number).",
            audit: .expanded(hundreds: hundreds, tens: tens, ones: ones)
        )
    }

    private static func compare(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        var left = 480
        var right = 408
        for _ in 0..<20 {
            if rng.bool() {
                let hundreds = rng.int(1...9) * 100
                left = hundreds + rng.int(0...99)
                right = hundreds + rng.int(0...99)
            } else {
                left = rng.int(100...999)
                right = rng.int(100...999)
            }
            if left != right { break }
        }
        if left == right { right = left + 1 }
        let winner = max(left, right)
        let loser = min(left, right)
        return pack(
            topic: .placeValue,
            level: level,
            prompt: "Which number is greater?",
            answer: .choice(String(winner)),
            hint: "Compare the hundreds first. If they match, compare the tens.",
            fallback: "Start at the largest place. The first place that differs decides it.",
            solution: "\(winner) is greater than \(loser).",
            choices: shuffled([String(left), String(right)], rng: &rng),
            audit: .compare(left, right)
        )
    }

    private static func round(numberRange: ClosedRange<Int>, place: Int, level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        var number = rng.int(numberRange)
        var spins = 0
        while number % place == 0, spins < 8 {
            number = rng.int(numberRange)
            spins += 1
        }
        if number % place == 0 {
            number += place / 2
        }
        let result = rounded(number, to: place)
        let unit = place == 100 ? "hundred" : "ten"
        let look = place == 100 ? "tens digit" : "ones digit"
        return pack(
            topic: .placeValue,
            level: level,
            prompt: "Round \(number) to the nearest \(unit).",
            answer: .integer(result),
            hint: "Look at the \(look). Five or more rounds up. Four or less stays down.",
            fallback: "Look at the next digit. Five or more rounds up. Four or less stays down.",
            solution: "\(number) rounded to the nearest \(unit) is \(result).",
            audit: .round(number: number, place: place)
        )
    }

    private static func digit(of number: Int, place: Int) -> Int {
        guard place > 0 else { return 0 }
        return (number / place) % 10
    }

    private static func countOf(_ digit: Int, in number: Int) -> Int {
        var rest = number
        var count = 0
        if rest == 0 { return digit == 0 ? 1 : 0 }
        while rest > 0 {
            if rest % 10 == digit { count += 1 }
            rest /= 10
        }
        return count
    }

    private static func placeName(_ place: Int) -> String {
        switch place {
        case 1: return "ones"
        case 10: return "tens"
        case 100: return "hundreds"
        case 1000: return "thousands"
        default: return "ones"
        }
    }

    private static func rounded(_ number: Int, to place: Int) -> Int {
        let remainder = number % place
        let down = number - remainder
        if remainder * 2 >= place {
            return down + place
        }
        return down
    }
}

enum WordProblems {
    static let names = ["Alex", "Jordan", "Maya", "Noah", "Priya", "Luis", "Sam", "Riley"]

    static func make(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        for _ in 0..<40 {
            let question = attempt(level: level, rng: &rng)
            if !promptLeaks(question) {
                return question
            }
        }
        return safeFallback(level: level)
    }

    private static func attempt(level: Int, rng: inout SplitMix64) -> GeneratedQuestion {
        switch level {
        case 1:
            return additionStory(rng: &rng, level: level)
        case 2:
            return subtractionStory(rng: &rng, level: level)
        case 3:
            return rng.bool() ? multiplyStory(rng: &rng, level: level) : divideStory(rng: &rng, level: level)
        case 4:
            return twoStepStory(rng: &rng, level: level)
        default:
            return rng.bool() ? multiplyThenSubtract(rng: &rng, level: level) : pizza(rng: &rng, level: level)
        }
    }

    private static func additionStory(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let name = pickName(rng: &rng)
        let left = rng.int(2...9)
        let right = rng.int(2...9)
        let answer = left + right
        let prompt: String
        let solution: String
        switch rng.int(0...2) {
        case 0:
            prompt = "\(name) has \(counted(left, "sticker", "stickers")). A friend gives \(name) \(counted(right, "more sticker", "more stickers")). How many stickers does \(name) have now?"
            solution = "\(name) has \(answer) stickers."
        case 1:
            prompt = "There are \(counted(left, "red balloon", "red balloons")) and \(counted(right, "blue balloon", "blue balloons")). How many balloons are there?"
            solution = "There are \(answer) balloons."
        default:
            prompt = "\(name) reads \(counted(left, "page", "pages")) in the morning and \(counted(right, "page", "pages")) after lunch. How many pages is that?"
            solution = "\(name) reads \(answer) pages."
        }
        return word(
            level: level,
            prompt: prompt,
            answer: answer,
            shown: [left, right],
            hint: "This story puts two amounts together. Add them.",
            solution: solution
        )
    }

    private static func subtractionStory(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let name = pickName(rng: &rng)
        let start = rng.int(8...18)
        let away = rng.int(2...(start - 2))
        let answer = start - away
        let prompt: String
        let solution: String
        switch rng.int(0...2) {
        case 0:
            prompt = "\(name) has \(counted(start, "grape", "grapes")) and eats \(away). How many grapes are left?"
            solution = "\(answer) grapes are left."
        case 1:
            prompt = "There are \(counted(start, "kid", "kids")) on the bus. \(away) get off. How many kids are still on the bus?"
            solution = "\(answer) kids are still on the bus."
        default:
            prompt = "\(name) has \(counted(start, "bead", "beads")). \(name) uses \(away) of them for a bracelet. How many beads are left?"
            solution = "\(answer) beads are left."
        }
        return word(
            level: level,
            prompt: prompt,
            answer: answer,
            shown: [start, away],
            hint: "This story takes some away. Subtract.",
            solution: solution
        )
    }

    private static func multiplyStory(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let groups = rng.int(2...12)
        let each = rng.int(2...12)
        let answer = groups * each
        let prompt: String
        let solution: String
        if rng.bool() {
            prompt = "There are \(counted(groups, "bag", "bags")) with \(counted(each, "apple", "apples")) in each bag. How many apples are there?"
            solution = "There are \(answer) apples."
        } else {
            let name = pickName(rng: &rng)
            prompt = "\(name) lines up \(counted(groups, "row", "rows")) of \(counted(each, "chair", "chairs")). How many chairs is that?"
            solution = "That is \(answer) chairs."
        }
        return word(
            level: level,
            prompt: prompt,
            answer: answer,
            shown: [groups, each],
            hint: "Equal groups means multiply.",
            solution: solution
        )
    }

    private static func divideStory(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let people = rng.int(2...12)
        let each = rng.int(2...12)
        let total = people * each
        let prompt: String
        let solution: String
        if rng.bool() {
            prompt = "\(counted(total, "cookie", "cookies")) are shared equally by \(counted(people, "friend", "friends")). How many cookies does each friend get?"
            solution = "Each friend gets \(each) cookies."
        } else {
            let name = pickName(rng: &rng)
            prompt = "\(name) has \(counted(total, "card", "cards")) in \(counted(people, "equal pile", "equal piles")). How many cards are in each pile?"
            solution = "Each pile has \(each) cards."
        }
        return word(
            level: level,
            prompt: prompt,
            answer: each,
            shown: [total, people],
            hint: "Shared into equal groups means divide.",
            solution: solution
        )
    }

    private static func twoStepStory(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let name = pickName(rng: &rng)
        let other = pickName(rng: &rng, avoiding: name)
        let start = rng.int(8...20)
        let found = rng.int(2...8)
        let given = rng.int(2...(start + found - 1))
        let answer = start + found - given
        let prompt = "\(name) has \(counted(start, "marble", "marbles")). \(name) finds \(counted(found, "more marble", "more marbles")), then gives \(counted(given, "marble", "marbles")) to \(other). How many marbles does \(name) have now?"
        return word(
            level: level,
            prompt: prompt,
            answer: answer,
            shown: [start, found, given],
            hint: "Two steps. Add the new ones first, then subtract the ones that are given away.",
            solution: "\(name) has \(answer) marbles."
        )
    }

    private static func multiplyThenSubtract(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let name = pickName(rng: &rng)
        let rows = rng.int(2...6)
        let each = rng.int(2...8)
        let planted = rows * each
        let picked = rng.int(1...(planted - 1))
        let answer = planted - picked
        let prompt = "\(name) plants \(counted(rows, "row", "rows")) with \(counted(each, "flower", "flowers")) in each row. \(counted(picked, "flower gets picked", "flowers get picked")). How many flowers are still in the garden?"
        return word(
            level: level,
            prompt: prompt,
            answer: answer,
            shown: [rows, each, picked],
            hint: "Two steps. Multiply the equal rows first, then subtract the ones that were picked.",
            solution: "\(answer) flowers are still in the garden."
        )
    }

    private static func pizza(rng: inout SplitMix64, level: Int) -> GeneratedQuestion {
        let name = pickName(rng: &rng)
        let slices = rng.pick([4, 6, 8, 10, 12])
        let eaten = rng.int(1...(slices - 1))
        let left = slices - eaten
        let fraction = Fraction(left, slices)
        let simple = fraction.simplified
        let written = fraction.display == simple.display
            ? fraction.display
            : "\(fraction.display), which is \(simple.display)"
        let prompt = "A pizza is cut into \(counted(slices, "equal slice", "equal slices")). \(name) eats \(eaten). What fraction of the pizza is left?"
        return pack(
            topic: .wordProblems,
            level: level,
            prompt: prompt,
            answer: .fraction(fraction, acceptEquivalent: true),
            hint: "The whole pizza is the bottom number. The slices left are the top number.",
            fallback: "The whole pizza is the bottom number. The slices left are the top number.",
            solution: "\(left) out of \(slices) slices are left, which is \(written).",
            audit: .wordFraction(numerator: left, denominator: slices, shown: [slices, eaten])
        )
    }

    private static func word(level: Int, prompt: String, answer: Int, shown: [Int], hint: String, solution: String) -> GeneratedQuestion {
        pack(
            topic: .wordProblems,
            level: level,
            prompt: prompt,
            answer: .integer(answer),
            hint: hint,
            fallback: "Look for the numbers and what the question asks you to find.",
            solution: solution,
            audit: .word(answer: answer, shown: shown)
        )
    }

    private static func promptLeaks(_ question: GeneratedQuestion) -> Bool {
        switch question.audit {
        case .word(let answer, _):
            return NumericText.contains(question.prompt, answer: String(answer))
        case .wordFraction(let numerator, let denominator, _):
            let fraction = Fraction(numerator, denominator)
            return NumericText.contains(question.prompt, answer: fraction.display)
                || NumericText.contains(question.prompt, answer: fraction.simplified.display)
        default:
            return false
        }
    }

    private static func safeFallback(level: Int) -> GeneratedQuestion {
        word(
            level: level,
            prompt: "Alex has 3 stickers. A friend gives Alex 2 more stickers. How many stickers does Alex have now?",
            answer: 5,
            shown: [3, 2],
            hint: "This story puts two amounts together. Add them.",
            solution: "Alex has 5 stickers."
        )
    }

    private static func pickName(rng: inout SplitMix64, avoiding: String? = nil) -> String {
        let pool = names.filter { $0 != avoiding }
        return rng.pick(pool)
    }

    private static func counted(_ n: Int, _ one: String, _ many: String) -> String {
        "\(n) \(n == 1 ? one : many)"
    }
}
