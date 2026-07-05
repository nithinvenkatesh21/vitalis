import Foundation
import Supabase

public final class VitalisSupabaseClient {
    public static let shared = VitalisSupabaseClient()
    
    public let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
    }
}
