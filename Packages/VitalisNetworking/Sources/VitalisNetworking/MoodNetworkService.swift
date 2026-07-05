import Foundation
import Supabase
import VitalisCore

public final class MoodNetworkService {
    private let supabase = VitalisSupabaseClient.shared.client
    
    public init() {}
    
    // DTO for deserializing database rows
    private struct MoodEntryDTO: Codable {
        let id: UUID
        let user_id: UUID
        let timestamp: Date
        let valence: Double
        let tags_json: [String]
        let free_text: String?
        
        func toDomain() -> MoodEntry {
            MoodEntry(
                id: id,
                userId: user_id,
                timestamp: timestamp,
                valence: valence,
                tags: tags_json,
                freeText: free_text,
                isSynced: true
            )
        }
    }
    
    private struct LogMoodRPCRequest: Codable {
        let p_valence: Double
        let p_tags_json: [String]
        let p_free_text: String?
        let p_timestamp: Date
        let p_event_type: String
        let p_event_payload: [String: String]
    }
    
    /// Fetches all mood entries for the authenticated user from Supabase.
    public func fetchMoodEntries() async throws -> [MoodEntry] {
        let dtos: [MoodEntryDTO] = try await supabase
            .from("mood_entries")
            .select()
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        return dtos.map { $0.toDomain() }
    }
    
    /// Push a MoodEntry and TimelineEvent atomically to Supabase via database RPC.
    public func pushMoodWithTimeline(mood: MoodEntry, event: TimelineEvent) async throws {
        let request = LogMoodRPCRequest(
            p_valence: mood.valence,
            p_tags_json: mood.tags,
            p_free_text: mood.freeText,
            p_timestamp: mood.timestamp,
            p_event_type: event.type,
            p_event_payload: event.payload
        )
        
        // This executes inside a database transaction on the backend.
        // If the connection drops or either insert fails, the transaction is aborted.
        _ = try await supabase
            .rpc("log_mood_with_timeline", params: request)
            .execute()
    }
}
