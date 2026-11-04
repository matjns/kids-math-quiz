#if os(macOS)
import SwiftUI
import MathQuizCore

struct ProgressScreen: View {
    @Bindable var model: MathQuizModel
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Text(model.progress.playerName.isEmpty ? "Your progress" : model.progress.playerName)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Button("Done") { dismiss() }
                        .buttonStyle(FilledButtonStyle())
                }
                if model.progress.answeredTotal == 0 {
                    Text(QuizCopy.emptyProgress)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                }
                HStack(spacing: 12) {
                    StatPill(symbol: "star.fill", tint: Theme.sun, text: "\(model.progress.stars)")
                    StatPill(symbol: "flame.fill", tint: Theme.coral, text: "Best \(model.progress.bestStreak)")
                    StatPill(symbol: "checkmark.circle.fill", tint: Theme.leaf, text: "\(model.progress.roundsFinished) rounds")
                }
                VStack(spacing: 10) {
                    ForEach(Topic.allCases, id: \.self) { topic in
                        TopicMeter(topic: topic, skill: model.progress.skill(for: topic))
                    }
                }
                if let next = BadgeRules.nextGoal(in: model.progress), !model.progress.badges.contains(next) {
                    Text("Next up: \(next.title). \(next.blurb)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.ink)
                }
                if model.progress.badges.isEmpty {
                    Text("Badges you earn show up here.")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                } else {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        ForEach(model.progress.badges, id: \.self) { badge in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(badge.title)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Text(badge.blurb)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .foregroundStyle(Theme.ink)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.sun.opacity(0.28), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
            .padding(28)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.paper)
        .frame(minWidth: 720, minHeight: 560)
    }
}

struct TopicMeter: View {
    var topic: Topic
    var skill: Skill

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: topic.symbolName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.blue)
                .frame(width: 36, height: 36)
                .background(Color.white, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.ink)
                Text(SkillLevelName.title(for: skill.level))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.ink.opacity(0.65))
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(1...QuizRules.maxLevel, id: \.self) { step in
                    Circle()
                        .fill(step <= skill.level ? Theme.blue : Theme.ink.opacity(0.12))
                        .frame(width: 12, height: 12)
                }
            }
            .accessibilityLabel("\(topic.title), \(SkillLevelName.title(for: skill.level))")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
#endif
