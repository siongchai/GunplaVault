import SwiftUI

struct AchievementsSection: View {
    let achievements: [Achievement]

    private var unlocked: [Achievement] {
        achievements.filter(\.isUnlocked)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(GVTypography.headline)
                Spacer()
                Text("\(unlocked.count)/\(achievements.count)")
                    .font(GVTypography.caption)
                    .foregroundStyle(GVColors.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(achievements) { achievement in
                        AchievementBadge(achievement: achievement)
                    }
                }
            }
        }
    }
}

struct AchievementBadge: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? GVColors.accent.opacity(0.2) : GVColors.surfaceSecondary)
                    .frame(width: 56, height: 56)
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundStyle(achievement.isUnlocked ? GVColors.accent : GVColors.textSecondary.opacity(0.4))
            }
            Text(achievement.title)
                .font(GVTypography.caption)
                .foregroundStyle(achievement.isUnlocked ? GVColors.textPrimary : GVColors.textSecondary)
                .lineLimit(1)
                .frame(width: 72)
        }
        .opacity(achievement.isUnlocked ? 1 : 0.6)
    }
}

#Preview {
    AchievementsSection(achievements: AchievementEngine.evaluate(items: [], hoursBuilt: 0, shelfCount: 0))
        .padding()
}
