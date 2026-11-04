public struct Fraction: Equatable, Hashable {
    public var numerator: Int
    public var denominator: Int

    public init(_ numerator: Int, _ denominator: Int) {
        self.numerator = numerator
        self.denominator = denominator
    }

    public var display: String {
        "\(numerator)/\(denominator)"
    }

    public var isSimplified: Bool {
        guard denominator > 0, numerator >= 0 else { return false }
        return gcd(numerator, denominator) == 1
    }

    public var simplified: Fraction {
        guard denominator != 0 else { return self }
        let divisor = gcd(abs(numerator), abs(denominator))
        let sign = denominator < 0 ? -1 : 1
        return Fraction(sign * numerator / divisor, abs(denominator) / divisor)
    }

    public func isEquivalent(to other: Fraction) -> Bool {
        guard denominator != 0, other.denominator != 0 else { return false }
        return numerator * other.denominator == other.numerator * denominator
    }
}

func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a)
    var y = abs(b)
    while y != 0 {
        let next = x % y
        x = y
        y = next
    }
    return max(x, 1)
}
