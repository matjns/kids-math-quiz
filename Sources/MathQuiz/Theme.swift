#if os(macOS)
import SwiftUI

enum Theme {
    static let paper = Color(red: 1.0, green: 0.965, blue: 0.91)
    static let ink = Color(red: 0.141, green: 0.192, blue: 0.251)
    static let blue = Color(red: 0.106, green: 0.310, blue: 0.612)
    static let sun = Color(red: 0.949, green: 0.718, blue: 0.12)
    static let leaf = Color(red: 0.12, green: 0.478, blue: 0.302)
    static let sand = Color(red: 1.0, green: 0.925, blue: 0.839)
    static let coral = Color(red: 0.769, green: 0.361, blue: 0.29)
    static let card = Color.white
}

struct BigChoice: View {
    var title: String
    var subtitle: String
    var fill: Color
    var ink: Color
    var action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(subtitle)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
            }
            .foregroundStyle(ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .background(fill.opacity(hover ? 0.9 : 1), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

struct QuietButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.8), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
#endif
