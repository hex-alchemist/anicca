import Foundation

/// Reserved for future deep Yggdrasil ↔ Anicca sync.
/// When implemented, this service will push CheckIn data to Yggdrasil's
/// Supabase instance using a shared user ID (`profiles.yggdrasil_user_id`).
protocol YggdrasilIntegrationProtocol {
    /// Push the user's Anicca check-ins to the linked Yggdrasil account.
    func syncCheckIns(_ checkIns: [CheckIn]) async throws

    /// Fetch journal entries from Yggdrasil for cross-app context.
    func fetchYggdrasilEntries() async throws -> [YggdrasilEntry]

    /// Link the user's Anicca account to a Yggdrasil user.
    func linkAccount(yggdrasilUserId: String) async throws
}

/// Placeholder type — replace with real model when integration is built.
struct YggdrasilEntry: Codable {
    let id: UUID
    let createdAt: Date
    let content: String
}
