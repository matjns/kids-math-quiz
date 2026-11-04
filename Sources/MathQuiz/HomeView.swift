#if os(macOS)
import SwiftUI
import MathQuizCore

struct RootView: View {
    @Bindable var model: MathQuizModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            switch model.phase {
            case .home:
                HomeView(model: model)
            case .question, .feedback:
                QuizView(model: model)
            case .summary:
                SummaryView(model: model)
            }
        }
        .preferredColorScheme(.light)
        .frame(minWidth: 960, minHeight: 700)
        .onAppear { model.installKeyMonitor() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                model.persist()
            }
        }
        .sheet(isPresented: $model.showProgress) {
            ProgressScreen(model: model)
        }
        .sheet(isPresented: $model.showNameEditor) {
            NameEditor(model: model)
        }
        .alert(QuizCopy.stopTitle, isPresented: $model.showStopConfirm) {
            Button(QuizCopy.goHome) { model.goHome() }
            Button(QuizCopy.keepPlaying, role: .cancel) {}
                .keyboardShortcut(.defaultAction)
        } message: {
            Text(QuizCopy.stopMessage)
        }
    }
}

struct HomeView: View {
    @Bindable var model: MathQuizModel

    var body: some View {
        VStack(spacing: 28) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(QuizCopy.greeting(name: model.progress.playerName))
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                        .minimumScaleFactor(0.6)
                    Text("Ten questions. Stars when you get them. A hint when you don't.")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.72))
                }
                Spacer(minLength: 16)
                QuietButton(title: QuizCopy.nameButton) {
                    model.beginNameEdit()
                }
            }

            HStack(spacing: 16) {
                StatPill(symbol: "star.fill", tint: Theme.sun, text: starText)
                StatPill(symbol: "flame.fill", tint: Theme.coral, text: streakText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 14) {
                BigChoice(
                    title: QuizCopy.practiceTitle,
                    subtitle: QuizCopy.practiceDetail,
                    fill: Theme.blue,
                    ink: .white,
                    action: model.startPractice
                )
                BigChoice(
                    title: QuizCopy.lightningTitle,
                    subtitle: QuizCopy.lightningDetail,
                    fill: Theme.sun,
                    ink: Theme.ink,
                    action: model.startLightning
                )
            }

            HStack {
                QuietButton(title: QuizCopy.progressTitle) {
                    model.showProgress = true
                }
                Spacer()
                if let saveWarning = model.saveWarning {
                    Text(saveWarning)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.coral)
                }
            }
        }
        .padding(40)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var starText: String {
        model.progress.stars == 1 ? "1 star" : "\(model.progress.stars) stars"
    }

    private var streakText: String {
        let streak = model.progress.bestStreak
        return streak == 1 ? "Best streak 1" : "Best streak \(streak)"
    }
}

struct StatPill: View {
    var symbol: String
    var tint: Color
    var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(text)
                .foregroundStyle(Theme.ink)
        }
        .font(.system(size: 20, weight: .bold, design: .rounded))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white, in: Capsule())
    }
}

struct NameEditor: View {
    @Bindable var model: MathQuizModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(QuizCopy.nameTitle)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.ink)
            Text(QuizCopy.nameNote)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
            TextField("Name", text: $model.nameDraft)
                .textFieldStyle(.plain)
                .font(.system(size: 28, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.ink)
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            HStack(spacing: 12) {
                Button(QuizCopy.saveName) { model.saveName() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(FilledButtonStyle())
                Button(QuizCopy.clearName) { model.clearName() }
                    .buttonStyle(PlainKidButtonStyle())
            }
        }
        .padding(28)
        .frame(width: 480)
        .background(Theme.paper)
    }
}

struct FilledButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Theme.blue.opacity(configuration.isPressed ? 0.85 : 1), in: Capsule())
    }
}

struct PlainKidButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Color.white.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
    }
}
#endif
