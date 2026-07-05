import Foundation
import Supabase
import VitalisCore

public final class ReadinessNetworkService {
    private let supabase = VitalisSupabaseClient.shared.client
    
    public init() {}
    
    private struct ReadinessScoreDTO: Codable {
        let id: UUID
        let user_id: UUID
        let date: Date
        let composite_score: Double
        let components_json: [String: Double]
        let explanation_json: [String]
        
        func toDomain() -> ReadinessScore {
            ReadinessScore(
                id: id,
                userId: user_id,
                date: date,
                compositeScore: composite_score,
                components: components_json,
                explanation: explanation_json,
                isSynced: true
            )
        }
    }
    
    private struct LogReadinessRPCRequest: Codable {
        let p_date: Date
        let p_composite_score: Double
        let p_components_json: [String: Double]
        let p_explanation_json: [String]
        let p_event_payload: [String: String]
    }
    
    /// Fetches all readiness scores for the authenticated user from Supabase.
    public func fetchReadinessScores() async throws -> [ReadinessScore] {
        let dtos: [ReadinessScoreDTO] = try await supabase
            .from("readiness_scores")
            .select()
            .order("date", ascending: false)
            .execute()
            .value
        
        return dtos.map { $0.toDomain() }
    }
    
    /// Push a ReadinessScore and TimelineEvent atomically to Supabase.
    public func pushReadinessScore(score: ReadinessScore, event: TimelineEvent) async throws {
        let request = LogReadinessRPCRequest(
            p_date: score.date,
            p_composite_score: score.compositeScore,
            p_components_json: score.components,
            p_explanation_json: score.explanation,
            p_event_payload: event.payload
        )
        
        _ = try await supabase
            .rpc("log_readiness_with_timeline", params: request)
            .execute()
    }
}
