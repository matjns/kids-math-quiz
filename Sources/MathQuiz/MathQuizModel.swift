#if os(macOS)
import AppKit
import Foundation
import Observation
import MathQuizCore

enum QuizPhase: Equatable {
    case home
    case question
    case feedback
    case summary
}

@Observable
final class MathQuizModel {
    var progress: QuizProgress
    var phase: QuizPhase = .home
    var engine: QuizEngine?
    var feedback: Feedback?
    var summary: RoundSummary?
    var entry = ""
    var secondsRemaining = QuizRules.lightningSeconds
    var showStopConfirm = false
    var showNameEditor = false
    var showProgress = false
    var nameDraft = ""
    var saveWarning: String?

    @ObservationIgnored private let store: ProgressStore
    @ObservationIgnored private var keyMonitor: Any?

    init(store: ProgressStore? = nil) {
        if let store {
            self.store = store
        } else {
            let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            self.store = ProgressStore(directory: MathQuizSupport.directory(home: home))
        }
        progress = self.store.load()
    }

    deinit {
        let monitor = keyMonitor
        // Drop the monitor only on the main thread. assumeIsolated traps if it is not.
        guard let monitor, Thread.isMainThread else { return }
        MainActor.assumeIsolated {
            NSEvent.removeMonitor(monitor)
        }
    }

    var timerID: String {
        guard phase == .question, let quiz = engine else { return "idle" }
        return "question-\(quiz.index)"
    }

    func installKeyMonitor() {
        guard keyMonitor == nil, Thread.isMainThread else { return }
        keyMonitor = MainActor.assumeIsolated {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, Thread.isMainThread else { return event }
                return MainActor.assumeIsolated {
                    let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                    if modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) {
                        return event
                    }
                    return self.handleKey(event) ? nil : event
                }
            }
        }
    }

    func startPractice() {
        start(settings: .practice)
    }

    func startLightning() {
        start(settings: .lightning)
    }

    func playAgain() {
        let lightning = engine?.settings.lightning ?? false
        start(settings: lightning ? .lightning : .practice)
    }

    func submitCurrent() {
        guard phase == .question, var quiz = engine else { return }
        guard let result = quiz.submit(response: entry, timedOut: false, progress: &progress) else { return }
        engine = quiz
        feedback = result
        phase = .feedback
        persist()
    }

    func timeExpired() {
        guard phase == .question, var quiz = engine else { return }
        guard let result = quiz.submit(response: entry, timedOut: true, progress: &progress) else { return }
        engine = quiz
        feedback = result
        phase = .feedback
        persist()
    }

    func next() {
        guard phase == .feedback, var quiz = engine else { return }
        if quiz.isComplete {
            summary = quiz.summary
            feedback = nil
            phase = .summary
            persist()
            return
        }
        quiz.advance(progress: progress)
        engine = quiz
        feedback = nil
        entry = ""
        secondsRemaining = quiz.settings.secondsPerQuestion
        phase = .question
    }

    func goHome() {
        engine = nil
        feedback = nil
        summary = nil
        entry = ""
        phase = .home
        showStopConfirm = false
        persist()
    }

    func beginNameEdit() {
        nameDraft = progress.playerName
        showNameEditor = true
    }

    func saveName() {
        progress.playerName = PlayerName.cleaned(nameDraft)
        showNameEditor = false
        persist()
    }

    func clearName() {
        nameDraft = ""
        progress.playerName = ""
        showNameEditor = false
        persist()
    }

    func choose(_ choice: String) {
        guard phase == .question else { return }
        entry = choice
        submitCurrent()
    }

    func appendDigit(_ digit: String) {
        guard phase == .question, let style = engine?.current?.entry else { return }
        switch style {
        case .choices:
            return
        case .wholeNumber:
            if entry == "0" {
                entry = digit
                return
            }
            guard entry.count < 6 else { return }
            entry.append(digit)
        case .fraction:
            guard let slash = entry.firstIndex(of: "/") else {
                if entry == "0" {
                    entry = digit
                    return
                }
                guard entry.count < 2 else { return }
                entry.append(digit)
                return
            }
            let denominator = entry[entry.index(after: slash)...]
            if denominator == "0" || denominator.count >= 2 { return }
            entry.append(digit)
        }
    }

    func appendSlash() {
        guard phase == .question, engine?.current?.entry == .fraction else { return }
        guard !entry.isEmpty, !entry.contains("/") else { return }
        entry.append("/")
    }

    func deleteLast() {
        guard phase == .question, !entry.isEmpty else { return }
        entry.removeLast()
    }

    /// Stays on the main thread after each pause so the clock and the time's-up card update the window.
    @MainActor
    func countDown() async {
        guard phase == .question, let quiz = engine, quiz.settings.lightning else { return }
        let token = timerID
        secondsRemaining = quiz.settings.secondsPerQuestion
        while secondsRemaining > 0 {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            if Task.isCancelled { return }
            guard phase == .question, timerID == token else { return }
            if showStopConfirm { continue }
            secondsRemaining -= 1
        }
        guard phase == .question, timerID == token else { return }
        timeExpired()
    }

    func persist() {
        do {
            try store.save(progress)
            saveWarning = nil
        } catch {
            saveWarning = "Progress could not be saved."
            let message = "Math Quiz could not save progress: \(error)\n"
            try? FileHandle.standardError.write(contentsOf: Data(message.utf8))
        }
    }

    private func start(settings: RoundSettings) {
        var rng = SystemRandomNumberGenerator()
        let seed = rng.next()
        let quiz = QuizEngine(progress: progress, settings: settings, seed: seed)
        guard quiz.current != nil else { return }
        engine = quiz
        feedback = nil
        summary = nil
        entry = ""
        secondsRemaining = settings.secondsPerQuestion
        showStopConfirm = false
        showNameEditor = false
        showProgress = false
        phase = .question
    }

    @MainActor
    private func handleKey(_ event: NSEvent) -> Bool {
        if showStopConfirm || showNameEditor || showProgress { return false }
        let characters = event.charactersIgnoringModifiers ?? ""
        if phase == .summary {
            if characters == "\r" || characters == "\n" {
                playAgain()
                return true
            }
            return false
        }
        if phase == .feedback {
            if characters == "\r" || characters == "\n" || characters == " " {
                next()
                return true
            }
            return false
        }
        guard phase == .question, let question = engine?.current else { return false }
        if characters == "\r" || characters == "\n" {
            if question.entry == .choices { return false }
            submitCurrent()
            return true
        }
        if event.keyCode == 51 || event.keyCode == 117 || characters == "\u{7F}" {
            deleteLast()
            return true
        }
        if question.entry == .choices {
            if let number = Int(characters), (1...question.choices.count).contains(number) {
                choose(question.choices[number - 1])
                return true
            }
            return false
        }
        if characters == "/" || characters == "⁄" {
            guard question.entry == .fraction else { return false }
            appendSlash()
            return true
        }
        if characters.count == 1, let character = characters.first, character.isNumber {
            appendDigit(String(character))
            return true
        }
        return false
    }
}
#endif
