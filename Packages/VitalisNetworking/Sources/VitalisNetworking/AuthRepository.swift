import Foundation
import Combine
import Supabase
import VitalisCore

public typealias User = VitalisCore.User

public final class AuthRepository: AuthRepositoryProtocol {
    private let supabase = VitalisSupabaseClient.shared.client
    
    private let userSubject = CurrentValueSubject<User?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    public var currentUser: User? {
        userSubject.value
    }
    
    public var currentUserPublisher: AnyPublisher<User?, Never> {
        userSubject.eraseToAnyPublisher()
    }
    
    public init() {
        // Observe auth state changes from Supabase
        Task {
            for await state in supabase.auth.authStateChanges {
                if let session = state.session {
                    let domainUser = self.mapUser(session.user)
                    self.userSubject.send(domainUser)
                } else {
                    self.userSubject.send(nil)
                }
            }
        }
    }
    
    public func signInWithApple(idToken: String, nonce: String) async throws -> User {
        let authResponse = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken
            )
        )
        let domainUser = mapUser(authResponse.user)
        userSubject.send(domainUser)
        return domainUser
    }
    
    public func signOut() async throws {
        try await supabase.auth.signOut()
        userSubject.send(nil)
    }
    
    #if DEBUG
    /// Mock Authentication for testing on simulators without configuring Apple Developer entitlement.
    /// Uses email/password or anonymous login to create a real session in Supabase, satisfying RLS.
    public func signInMock(userId: UUID, displayName: String) async throws -> User {
        let testEmail = "debug_\(userId.uuidString.lowercased())@vitalis.test"
        let testPassword = "DebugPassword123!"
        
        do {
            // Try to sign in first
            let authResponse = try await supabase.auth.signIn(
                email: testEmail,
                password: testPassword
            )
            let domainUser = mapUser(authResponse.user)
            userSubject.send(domainUser)
            return domainUser
        } catch {
            // If sign in fails, attempt to sign up the test user
            _ = try await supabase.auth.signUp(
                email: testEmail,
                password: testPassword,
                data: ["display_name": .string(displayName)]
            )
            
            // Try to sign in again after signup
            let authResponse = try await supabase.auth.signIn(
                email: testEmail,
                password: testPassword
            )
            let domainUser = mapUser(authResponse.user)
            userSubject.send(domainUser)
            return domainUser
        }
    }
    #endif
    
    private func mapUser(_ supabaseUser: Supabase.User) -> User {
        let displayName = supabaseUser.userMetadata["display_name"] as? String 
            ?? supabaseUser.email 
            ?? "User"
        return User(
            id: supabaseUser.id,
            displayName: displayName,
            createdAt: supabaseUser.createdAt
        )
    }
}
