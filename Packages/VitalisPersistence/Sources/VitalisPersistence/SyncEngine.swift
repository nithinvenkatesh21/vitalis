import Foundation
import SwiftData
import VitalisCore
import VitalisNetworking

public final class SyncEngine {
    private let dataController = VitalisDataController.shared
    private let authRepository: AuthRepositoryProtocol
    
    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    @MainActor
    public func processOutbox() async {
        // No-op in local-only mode.
    }
}
