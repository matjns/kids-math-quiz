#if os(macOS)
import SwiftUI
import MathQuizCore

struct QuizView: View {
    @Bindable var model: MathQuizModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if showsTimer {
                    timer
                }
                Spacer(minLength: 4)
                if let question = model.engine?.current {
                    Text(question.prompt)
                        .font(.system(size: promptSize(question.prompt), weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .accessibilityAddTraits(.isHeader)
                    if model.phase == .feedback, let feedback = model.feedback {
                        feedbackCard(feedback)
                    } else {
                        answering(question)
                    }
                }
                Spacer(minLength: 4)
            }
            .padding(32)
            .frame(maxWidth: 860)
            .frame(maxWidth: .infinity, minHeight: 640)
        }
        .scrollContentBackground(.hidden)
        .task(id: model.timerID) {
            await model.countDown()
        }
    }

    private var showsTimer: Bool {
        model.phase == .question && model.engine?.settings.lightning == true
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let quiz = model.engine {
                Text(QuizCopy.questionProgress(index: quiz.index + 1, total: quiz.plan.count))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                if let topic = quiz.current?.topic {
                    Text(topic.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white, in: Capsule())
                }
            }
            Spacer()
            if model.progress.currentStreak > 0 {
                StatPill(symbol: "flame.fill", tint: Theme.coral, text: "\(model.progress.currentStreak)")
            }
            StatPill(symbol: "star.fill", tint: Theme.sun, text: "\(model.progress.stars)")
            QuietButton(title: QuizCopy.stopButton) {
                model.showStopConfirm = true
            }
        }
    }

    private var timer: some View {
        VStack(alignment: .leading, spacing: 6) {
            TimerBar(
                fraction: timerFraction,
                urgent: model.secondsRemaining <= 5
            )
            .accessibilityLabel("\(model.secondsRemaining) seconds left")
            Text(model.secondsRemaining == 1 ? "1 second" : "\(model.secondsRemaining) seconds")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(model.secondsRemaining <= 5 ? Theme.coral : Theme.ink.opacity(0.65))
        }
    }

    private var timerFraction: Double {
        let total = Double(model.engine?.settings.secondsPerQuestion ?? QuizRules.lightningSeconds)
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(model.secondsRemaining) / total))
    }

    @ViewBuilder
    private func answering(_ question: Question) -> some View {
        switch question.entry {
        case .choices:
            VStack(spacing: 12) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                    ChoiceButton(index: index + 1, title: choice) {
                        model.choose(choice)
                    }
                }
            }
        case .wholeNumber, .fraction:
            EntryWell(entry: model.entry, fraction: question.entry == .fraction)
            AnswerPad(
                fraction: question.entry == .fraction,
                checkEnabled: EntryCheck.isReady(model.entry, style: question.entry),
                onDigit: model.appendDigit,
                onSlash: model.appendSlash,
                onDelete: model.deleteLast,
                onCheck: model.submitCurrent
            )
        }
    }

    private func feedbackCard(_ feedback: Feedback) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(feedback.message)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let hint = feedback.hint {
                Text(hint)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 10) {
                if let starNote = feedback.starNote {
                    Text(starNote)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.sun, in: Capsule())
                }
                if let levelNote = feedback.levelNote {
                    Text(levelNote)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.leaf)
                }
            }
            if !feedback.newBadges.isEmpty {
                Text(feedback.newBadges.map(\.title).joined(separator: "  ·  "))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.blue)
            }
            Button(model.engine?.isComplete == true ? QuizCopy.finish : QuizCopy.next) {
                model.next()
            }
            .buttonStyle(FilledButtonStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            feedback.correct ? Theme.leaf.opacity(0.16) : Theme.sand,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func promptSize(_ prompt: String) -> CGFloat {
        if prompt.count > 90 { return 32 }
        if prompt.count > 48 { return 40 }
        return 56
    }
}

struct SummaryView: View {
    @Bindable var model: MathQuizModel

    var body: some View {
        VStack(spacing: 22) {
            if let summary = model.summary {
                Text(QuizCopy.outOf(correct: summary.correct, total: summary.total))
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                    .minimumScaleFactor(0.5)
                Text(summary.encouragement)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.8))
                    .multilineTextAlignment(.center)
                Text(QuizCopy.roundStars(summary.stars))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(QuizCopy.altogether(model.progress.stars))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                if !summary.newBadges.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(summary.newBadges, id: \.self) { badge in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(badge.title)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text(badge.blurb)
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(Theme.ink)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.sun.opacity(0.35), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            HStack(spacing: 12) {
                Button(QuizCopy.playAgain) { model.playAgain() }
                    .buttonStyle(FilledButtonStyle())
                Button(QuizCopy.home) { model.goHome() }
                    .buttonStyle(PlainKidButtonStyle())
            }
        }
        .padding(40)
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TimerBar: View {
    var fraction: Double
    var urgent: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ink.opacity(0.1))
                Capsule()
                    .fill(urgent ? Theme.coral : Theme.blue)
                    .frame(width: max(10, geo.size.width * fraction))
            }
        }
        .frame(height: 14)
    }
}

struct EntryWell: View {
    var entry: String
    var fraction: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
            if entry.isEmpty {
                Text(QuizCopy.placeholder)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.35))
            } else if fraction, let slash = entry.firstIndex(of: "/") {
                let numerator = String(entry[..<slash])
                let denominator = String(entry[entry.index(after: slash)...])
                VStack(spacing: 4) {
                    Text(numerator.isEmpty ? " " : numerator)
                    Rectangle()
                        .fill(Theme.ink)
                        .frame(width: 84, height: 3)
                    Text(denominator.isEmpty ? " " : denominator)
                }
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            } else {
                Text(entry)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 112)
        .accessibilityLabel(entry.isEmpty ? QuizCopy.placeholder : entry)
    }
}

struct AnswerPad: View {
    var fraction: Bool
    var checkEnabled: Bool
    var onDigit: (String) -> Void
    var onSlash: () -> Void
    var onDelete: () -> Void
    var onCheck: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9"], id: \.self) { digit in
                    PadKey(title: digit) { onDigit(digit) }
                }
                PadKey(title: "⌫", fill: Theme.sand) { onDelete() }
                    .accessibilityLabel("Delete")
                PadKey(title: "0") { onDigit("0") }
                if fraction {
                    PadKey(title: "/", fill: Theme.sand) { onSlash() }
                        .accessibilityLabel("Fraction bar")
                } else {
                    PadKey(title: QuizCopy.check, fill: Theme.blue, ink: .white, enabled: checkEnabled, action: onCheck)
                }
            }
            if fraction {
                Button(QuizCopy.check, action: onCheck)
                    .buttonStyle(FilledButtonStyle())
                    .disabled(!checkEnabled)
                    .opacity(checkEnabled ? 1 : 0.45)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

struct PadKey: View {
    var title: String
    var fill: Color = .white
    var ink: Color = Theme.ink
    var enabled: Bool = true
    var action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: title.count > 1 ? 22 : 32, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(fill.opacity(hover ? 0.88 : 1), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.45)
        .onHover { hover = $0 }
    }
}

struct ChoiceButton: View {
    var index: Int
    var title: String
    var action: () -> Void

    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text("\(index)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Theme.blue, in: Circle())
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 84)
            .background(Color.white.opacity(hover ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
        .accessibilityLabel("Choice \(index), \(title)")
    }
}
#endif
