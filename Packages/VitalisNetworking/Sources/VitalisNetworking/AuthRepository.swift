import Foundation
import Combine
import VitalisCore

public typealias User = VitalisCore.User

public final class AuthRepository: AuthRepositoryProtocol {
    private let userSubject = CurrentValueSubject<User?, Never>(nil)
    private let userDefaultsKey = "vitalis_current_user"
    
    public var currentUser: User? {
        userSubject.value
    }
    
    public var currentUserPublisher: AnyPublisher<User?, Never> {
        userSubject.eraseToAnyPublisher()
    }
    
    public init() {
        // Load persisted user session from UserDefaults
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            userSubject.send(user)
        }
    }
    
    public func signInWithApple(idToken: String, nonce: String) async throws -> User {
        // Mock Apple login locally: generate or load user
        let user = User(
            id: UUID(),
            displayName: "Apple User",
            createdAt: Date()
        )
        try saveUser(user)
        return user
    }
    
    public func signOut() async throws {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        userSubject.send(nil)
    }
    
    #if DEBUG
    public func signInMock(userId: UUID, displayName: String) async throws -> User {
        let user = User(
            id: userId,
            displayName: displayName,
            createdAt: Date()
        )
        try saveUser(user)
        return user
    }
    #endif
    
    private func saveUser(_ user: User) throws {
        let data = try JSONEncoder().encode(user)
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
        userSubject.send(user)
    }
}
