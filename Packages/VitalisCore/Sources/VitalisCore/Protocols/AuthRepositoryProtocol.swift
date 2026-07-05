import Foundation
import Combine

public protocol AuthRepositoryProtocol: AnyObject {
    var currentUser: User? { get }
    var currentUserPublisher: AnyPublisher<User?, Never> { get }
    
    func signInWithApple(idToken: String, nonce: String) async throws -> User
    func signOut() async throws
    
    #if DEBUG
    func signInMock(userId: UUID, displayName: String) async throws -> User
    #endif
}
