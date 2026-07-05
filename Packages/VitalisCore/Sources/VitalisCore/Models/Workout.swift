import Foundation

public enum WorkoutType: String, CaseIterable, Codable {
    case strength = "STRENGTH"
    case run = "RUN"
    case bike = "BIKE"
    case swim = "SWIM"
    case row = "ROW"
    case hike = "HIKE"
    case mobility = "MOBILITY"
    case other = "OTHER"
    
    public var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .run: return "Running"
        case .bike: return "Cycling"
        case .swim: return "Swimming"
        case .row: return "Rowing"
        case .hike: return "Hiking"
        case .mobility: return "Mobility"
        case .other: return "Other"
        }
    }
}

public struct SetLog: Codable, Identifiable, Equatable {
    public let id: UUID
    public let load: Double?
    public let reps: Int
    public let tempo: String?
    public let rpe: Double?
    public let restSeconds: Int?
    
    public init(id: UUID = UUID(), load: Double?, reps: Int, tempo: String?, rpe: Double?, restSeconds: Int?) {
        self.id = id
        self.load = load
        self.reps = reps
        self.tempo = tempo
        self.rpe = rpe
        self.restSeconds = restSeconds
    }
}

public extension SetLog {
    var estimatedOneRepMax: Double? {
        guard let load = load, reps > 0 else { return nil }
        if reps == 1 { return load }
        return load * (1.0 + Double(reps) / 30.0)
    }
}
