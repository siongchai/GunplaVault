import Foundation

struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
}

enum AchievementEngine {
    static func evaluate(items: [CollectionItem], hoursBuilt: Double, shelfCount: Int) -> [Achievement] {
        let total = items.count
        let completed = items.filter { $0.status == .completed }.count
        let grades = Set(items.map(\.grade))

        return [
            Achievement(
                id: "first_kit",
                title: "First Kit",
                description: "Added your first kit to the vault.",
                icon: "shippingbox.fill",
                isUnlocked: total >= 1
            ),
            Achievement(
                id: "collector",
                title: "Collector",
                description: "Cataloged 10 kits.",
                icon: "square.grid.2x2.fill",
                isUnlocked: total >= 10
            ),
            Achievement(
                id: "vault_keeper",
                title: "Vault Keeper",
                description: "Built a collection of 25 kits.",
                icon: "lock.shield.fill",
                isUnlocked: total >= 25
            ),
            Achievement(
                id: "master_builder",
                title: "Master Builder",
                description: "Completed 5 builds.",
                icon: "hammer.fill",
                isUnlocked: completed >= 5
            ),
            Achievement(
                id: "pro_builder",
                title: "Pro Builder",
                description: "Completed 25 builds.",
                icon: "star.fill",
                isUnlocked: completed >= 25
            ),
            Achievement(
                id: "marathon",
                title: "Marathon",
                description: "Logged 10+ hours of build time.",
                icon: "timer",
                isUnlocked: hoursBuilt >= 10
            ),
            Achievement(
                id: "grade_hg",
                title: "HG Enthusiast",
                description: "Own at least one HG kit.",
                icon: "1.circle.fill",
                isUnlocked: grades.contains(.hg)
            ),
            Achievement(
                id: "grade_mg",
                title: "Master Grade",
                description: "Own at least one MG kit.",
                icon: "m.circle.fill",
                isUnlocked: grades.contains(.mg) || grades.contains(.mgex)
            ),
            Achievement(
                id: "shelf_display",
                title: "On Display",
                description: "Created a virtual shelf.",
                icon: "photo.on.rectangle.angled",
                isUnlocked: shelfCount >= 1
            )
        ]
    }
}
