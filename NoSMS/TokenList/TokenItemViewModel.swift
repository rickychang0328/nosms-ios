import Foundation
import Combine
import OneTimePassword

class TokenItemViewModel: ObservableObject, Identifiable {
    let id: Data
    @Published var name: String
    @Published var issuer: String
    @Published var currentPassword: String = ""
    @Published var remainingSeconds: Double = 0.0
    @Published var isPin: Bool = false
    
    let token: Token
    let persistentToken: PersistentToken
    let refreshTimes: TimeInterval
    let isOnTime: Bool
    
    private var cancellables = Set<AnyCancellable>()
    private let tokenService: TokenService
    
    init(persistentToken: PersistentToken, timerPublisher: AnyPublisher<Date, Never>, tokenService: TokenService = .shared) {
        self.persistentToken = persistentToken
        self.token = persistentToken.token
        self.id = persistentToken.identifier
        self.name = persistentToken.token.name
        self.issuer = persistentToken.token.issuer
        self.tokenService = tokenService
        
        self.isPin = tokenService.pinList.contains(self.id)
        
        switch persistentToken.token.generator.factor {
        case .counter:
            self.refreshTimes = 0
            self.isOnTime = false
            self.currentPassword = persistentToken.token.currentPassword ?? ""
        case .timer(let period):
            self.refreshTimes = period
            self.isOnTime = true
            setupTimer(timerPublisher, period: period)
        }
        
        // Listen to changes in the global pin list to keep isPin updated
        tokenService.$pinList
            .map { $0.contains(self.id) }
            .assign(to: \.isPin, on: self)
            .store(in: &cancellables)
    }
    
    private func setupTimer(_ timerPublisher: AnyPublisher<Date, Never>, period: TimeInterval) {
        timerPublisher
            .sink { [weak self] date in
                guard let self = self else { return }
                let now = date.timeIntervalSince1970
                let elapsed = now.truncatingRemainder(dividingBy: period)
                let remaining = period - elapsed
                
                // Update password at the start of a new period
                if Int(elapsed) == 0 {
                    self.currentPassword = self.persistentToken.token.currentPassword ?? ""
                }
                self.remainingSeconds = remaining
            }
            .store(in: &cancellables)
            
        // Initial setup
        let now = Date().timeIntervalSince1970
        let elapsed = now.truncatingRemainder(dividingBy: period)
        self.remainingSeconds = period - elapsed
        self.currentPassword = persistentToken.token.currentPassword ?? ""
    }
    
    // Generates a new password for HOTP (counter-based)
    func generateOnTapPassword() {
        guard !isOnTime else { return }
        let updated = token.updatedToken()
        do {
            try tokenService.saveToken(updated, toPersistentToken: persistentToken)
            self.currentPassword = updated.currentPassword ?? ""
        } catch {
            print("Failed to save counter-based token: \(error)")
        }
    }
    
    func togglePin() {
        if isPin {
            tokenService.tokenRemovePin(id: id)
        } else {
            tokenService.tokenAddPin(id: id)
        }
    }
    
    func updateName(_ newName: String) {
        guard newName != name, newName.count <= 100 else { return } // Align with MustAuth limits
        let updated = Token(name: newName, issuer: issuer, generator: token.generator)
        try? tokenService.saveToken(updated, toPersistentToken: persistentToken)
        self.name = newName
    }
    
    func updateIssuer(_ newIssuer: String) {
        guard newIssuer != issuer, newIssuer.count <= 100 else { return }
        let updated = Token(name: name, issuer: newIssuer, generator: token.generator)
        try? tokenService.saveToken(updated, toPersistentToken: persistentToken)
        self.issuer = newIssuer
    }
}
