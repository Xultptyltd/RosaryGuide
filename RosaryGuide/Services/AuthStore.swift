import AuthenticationServices
import CryptoKit
import DeviceCheck
import Foundation
import FirebaseAppCheck
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import Observation
import Security
import UIKit

@MainActor
@Observable
final class AuthStore: NSObject {
    enum Provider: String {
        case apple = "Apple"
        case google = "Google"
        case anonymous = "Not signed in"
    }

    private(set) var userID: String?
    private(set) var provider: Provider = .anonymous
    /// Name from the sign-in provider, when it shared one.
    private(set) var displayName: String?
    private(set) var isWorking = false
    var errorMessage: String?

    private var authHandle: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?
    /// One-time Apple authorization code from the most recent re-authentication.
    /// Used only to revoke Sign in with Apple tokens during account deletion; never stored.
    private var pendingAppleAuthorizationCode: String?
    private var appleAuthPurpose: AppleAuthPurpose?
    private weak var presentationWindow: UIWindow?

    var isSignedIn: Bool { userID != nil }

    private enum AppleAuthPurpose {
        case signIn
        case reauthenticate(@MainActor @Sendable (Bool) -> Void)
    }

    override init() {
        super.init()
        configureFirebaseIfNeeded()
        apply(user: FirebaseApp.app() == nil ? nil : Auth.auth().currentUser)
        observeAuthState()
    }

    func signInWithApple() {
        guard FirebaseApp.app() != nil else {
            errorMessage = "Firebase is not configured yet. Add GoogleService-Info.plist to finish account setup."
            return
        }

        let nonce = Self.randomNonceString()
        currentNonce = nonce
        appleAuthPurpose = .signIn

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.nonce = Self.sha256(nonce)

        isWorking = true
        errorMessage = nil

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func signInWithGoogle() {
        guard FirebaseApp.app() != nil else {
            errorMessage = "Firebase is not configured yet. Add GoogleService-Info.plist to finish account setup."
            return
        }
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google Sign-In needs CLIENT_ID in GoogleService-Info.plist."
            return
        }
        guard let root = Self.rootViewController() else {
            errorMessage = "Could not find a window to present Google Sign-In."
            return
        }

        isWorking = true
        errorMessage = nil
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: root) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.finishWith(error.localizedDescription)
                    return
                }
                guard
                    let user = result?.user,
                    let idToken = user.idToken?.tokenString
                else {
                    self.finishWith("Google Sign-In did not return an identity token.")
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: user.accessToken.tokenString
                )
                self.signIn(with: credential)
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            apply(user: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Deletes the Firebase Auth account. Call only after `reauthenticateForSensitiveOperation`
    /// succeeded and the user's cloud data has been deleted.
    ///
    /// Order: revoke Sign in with Apple tokens (needs the signed-in user), delete the Auth user,
    /// then revoke the Google grant and sign out of Google locally.
    func deleteAccount(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "No account is signed in."
            completion(false)
            return
        }

        let deletedProvider = provider
        let appleCode = pendingAppleAuthorizationCode
        pendingAppleAuthorizationCode = nil
        isWorking = true
        errorMessage = nil

        Task { @MainActor in
            if deletedProvider == .apple {
                if let appleCode {
                    // Firebase calls Apple's /auth/revoke endpoint server-side. This only works when the
                    // Apple provider in the Firebase console has the Services ID, Team ID, Key ID and
                    // private key filled in. A failure must not block deletion, so it is logged only.
                    do {
                        try await Auth.auth().revokeToken(withAuthorizationCode: appleCode)
                    } catch {
                        #if DEBUG
                        print("Sign in with Apple token revocation failed: \(error.localizedDescription)")
                        #endif
                    }
                } else {
                    #if DEBUG
                    print("Sign in with Apple token revocation skipped: no authorization code.")
                    #endif
                }
            }

            do {
                try await user.delete()
            } catch {
                self.finishWith(Self.deleteAccountMessage(for: error))
                completion(false)
                return
            }

            if deletedProvider == .google, GIDSignIn.sharedInstance.currentUser != nil {
                // Revokes this app's Google OAuth grant and clears Google Sign-In's keychain entry.
                GIDSignIn.sharedInstance.disconnect { _ in }
            } else {
                GIDSignIn.sharedInstance.signOut()
            }
            self.apply(user: nil)
            self.isWorking = false
            completion(true)
        }
    }

    /// Clears anything kept for a deletion that will not go ahead.
    func cancelPendingAccountDeletion() {
        pendingAppleAuthorizationCode = nil
        isWorking = false
    }

    func reauthenticateForSensitiveOperation(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        guard FirebaseApp.app() != nil else {
            errorMessage = "Firebase is not configured yet."
            completion(false)
            return
        }
        guard Auth.auth().currentUser != nil else {
            errorMessage = "No account is signed in."
            completion(false)
            return
        }

        switch provider {
        case .apple:
            reauthenticateWithApple(completion: completion)
        case .google:
            reauthenticateWithGoogle(completion: completion)
        case .anonymous:
            errorMessage = "No account is signed in."
            completion(false)
        }
    }

    func handleOpenURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    private func configureFirebaseIfNeeded() {
        guard FirebaseApp.app() == nil else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }
        #if DEBUG
        AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
        #else
        AppCheck.setAppCheckProviderFactory(RosaryGuideAppCheckProviderFactory())
        #endif
        FirebaseApp.configure()
    }

    private func observeAuthState() {
        guard FirebaseApp.app() != nil else { return }
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.apply(user: user)
            }
        }
    }

    private func signIn(with credential: AuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.finishWith(error.localizedDescription)
                    return
                }
                self.apply(user: result?.user)
                self.isWorking = false
            }
        }
    }

    private func reauthenticateWithApple(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        pendingAppleAuthorizationCode = nil
        appleAuthPurpose = .reauthenticate(completion)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.nonce = Self.sha256(nonce)

        isWorking = true
        errorMessage = nil

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func reauthenticateWithGoogle(completion: @escaping @MainActor @Sendable (Bool) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Google Sign-In needs CLIENT_ID in GoogleService-Info.plist."
            completion(false)
            return
        }
        guard let root = Self.rootViewController() else {
            errorMessage = "Could not find a window to present Google Sign-In."
            completion(false)
            return
        }

        isWorking = true
        errorMessage = nil
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.signIn(withPresenting: root) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.finishWith(Self.isCancellation(error) ? nil : error.localizedDescription)
                    completion(false)
                    return
                }
                guard
                    let googleUser = result?.user,
                    let idToken = googleUser.idToken?.tokenString,
                    let firebaseUser = Auth.auth().currentUser
                else {
                    self.finishWith("Google did not return a usable identity token.")
                    completion(false)
                    return
                }

                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: googleUser.accessToken.tokenString
                )
                firebaseUser.reauthenticate(with: credential) { [weak self] _, error in
                    Task { @MainActor in
                        guard let self else { return }
                        if let error {
                            self.finishWith(Self.reauthenticationMessage(for: error))
                            completion(false)
                            return
                        }

                        self.isWorking = false
                        completion(true)
                    }
                }
            }
        }
    }

    private func finishWith(_ message: String?) {
        errorMessage = message
        isWorking = false
    }

    private func apply(user: User?) {
        userID = user?.uid
        provider = Self.provider(for: user)
        let name = (user?.displayName ?? user?.providerData.compactMap(\.displayName).first)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        displayName = (name?.isEmpty ?? true) ? nil : name
    }

    private static func provider(for user: User?) -> Provider {
        guard let providerID = user?.providerData.first?.providerID else { return .anonymous }
        if providerID == "apple.com" { return .apple }
        if providerID == "google.com" { return .google }
        return .anonymous
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            guard status == errSecSuccess else {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if Int(random) < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }

    private static func deleteAccountMessage(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain else { return error.localizedDescription }
        switch AuthErrorCode(rawValue: nsError.code) {
        case .requiresRecentLogin, .userTokenExpired, .invalidUserToken:
            return "For your security, please confirm your sign-in again, then try Delete account once more."
        case .networkError:
            return "You appear to be offline. Connect to the internet and try again."
        case .tooManyRequests:
            return "Too many attempts. Wait a few minutes and try again."
        default:
            return error.localizedDescription
        }
    }

    private static func reauthenticationMessage(for error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == AuthErrorDomain {
            switch AuthErrorCode(rawValue: nsError.code) {
            case .userMismatch:
                return "That sign-in belongs to a different account. Choose the account you're signed in with."
            case .networkError:
                return "You appear to be offline. Connect to the internet and try again."
            default:
                break
            }
        }
        return error.localizedDescription
    }

    /// The user closed the Apple or Google sheet; not an error worth showing.
    private static func isCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == ASAuthorizationError.errorDomain, nsError.code == ASAuthorizationError.canceled.rawValue {
            return true
        }
        if nsError.domain == kGIDSignInErrorDomain, nsError.code == GIDSignInError.canceled.rawValue {
            return true
        }
        return false
    }
}

private final class RosaryGuideAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if DCAppAttestService.shared.isSupported {
            return AppAttestProvider(app: app)
        }
        return DeviceCheckProvider(app: app)
    }
}

extension AuthStore: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let nonce = currentNonce,
                let tokenData = credential.identityToken,
                let tokenString = String(data: tokenData, encoding: .utf8)
            else {
                finishWith("Apple Sign-In did not return a usable identity token.")
                if case .reauthenticate(let completion) = appleAuthPurpose {
                    appleAuthPurpose = nil
                    completion(false)
                }
                return
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nonce,
                fullName: nil
            )
            switch appleAuthPurpose {
            case .signIn, nil:
                signIn(with: firebaseCredential)
            case .reauthenticate(let completion):
                guard let user = Auth.auth().currentUser else {
                    appleAuthPurpose = nil
                    finishWith("No account is signed in.")
                    completion(false)
                    return
                }
                let authorizationCode = credential.authorizationCode.flatMap { String(data: $0, encoding: .utf8) }
                user.reauthenticate(with: firebaseCredential) { [weak self] _, error in
                    Task { @MainActor in
                        guard let self else { return }
                        if let error {
                            self.appleAuthPurpose = nil
                            self.finishWith(Self.reauthenticationMessage(for: error))
                            completion(false)
                            return
                        }

                        self.pendingAppleAuthorizationCode = authorizationCode
                        self.appleAuthPurpose = nil
                        self.isWorking = false
                        completion(true)
                    }
                }
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            let message = Self.isCancellation(error) ? nil : error.localizedDescription
            if case .reauthenticate(let completion) = appleAuthPurpose {
                appleAuthPurpose = nil
                finishWith(message)
                completion(false)
                return
            }
            finishWith(message)
        }
    }
}

extension AuthStore: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let window = Self.rootViewController()?.view.window ?? UIWindow()
            presentationWindow = window
            return window
        }
    }
}
