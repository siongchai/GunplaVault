import Foundation

enum SubscriptionTier: String, Codable, CaseIterable {
    case free
    case pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }
}

struct AuthSession: Equatable {
    let userID: String
    let email: String
    let accessToken: String
}

struct UserProfile: Identifiable, Equatable, Codable {
    let id: String
    var displayName: String
    var email: String
    var avatarURL: String?
    var tier: SubscriptionTier
    var builderSince: Date
    var kitCount: Int
    var completedCount: Int
    var hoursBuilt: Double

    static let placeholder = UserProfile(
        id: "preview",
        displayName: "Builder",
        email: "builder@example.com",
        avatarURL: nil,
        tier: .free,
        builderSince: Date(),
        kitCount: 0,
        completedCount: 0,
        hoursBuilt: 0
    )
}

enum KitGrade: String, Codable, CaseIterable, Identifiable {
    case hg = "HG"
    case rg = "RG"
    case mg = "MG"
    case mgex = "MGEX"
    case pg = "PG"
    case sd = "SD"
    case pBandai = "P-Bandai"
    case other = "Other"

    var id: String { rawValue }
}

enum CollectionStatus: String, Codable, CaseIterable {
    case backlog
    case inProgress = "in_progress"
    case completed

    var displayName: String {
        switch self {
        case .backlog: return "Backlog"
        case .inProgress: return "Building"
        case .completed: return "Completed"
        }
    }
}

/// Catalog kit from the seed database (not yet in the user's collection).
struct SeedKit: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let series: String
    let grade: KitGrade
    let scale: String
    let releaseYear: Int
    let partCount: Int?
    let modelNumber: String?
    let barcode: String?
    let boxArtURL: String?
    let description: String?
    let isBandai: Bool
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, series, grade, scale, releaseYear, partCount, modelNumber, barcode, tags, description, isBandai
        case boxArtURL = "boxArtUrl"
    }
}

struct SeedDatabase: Codable {
    let version: Int
    let updatedAt: String
    let kits: [SeedKit]
}
