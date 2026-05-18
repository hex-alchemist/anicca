import Foundation
import Supabase

final class SupabaseConfig {
    static let shared = SupabaseConfig()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey
        )
    }
}
