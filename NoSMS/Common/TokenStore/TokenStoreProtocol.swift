import Foundation
import OneTimePassword
import RxCocoa
import RxSwift

protocol TokenStoreProtocol {
    
    var persistentTokensBehavior: BehaviorSubject<[AdapterTokenProtocol]>  { get }

    func addToken(_ token: Token) throws
    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws
    func updatePersistentToken(_ persistentToken: PersistentToken) throws
    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) throws
    func deleteToken(index: Int) throws
    func addTokenWith(urlString: String) throws
}

protocol AdapterTokenProtocol {
    
    var tokenType: Generator.Factor { get }
    var passwordAlgorithm: Generator.Algorithm { get }
    var password: BehaviorSubject<String> { get }
    var name: BehaviorSubject<String>  { get }
    var issuer: BehaviorSubject<String>  { get }
    var refreshTimes: TimeInterval { get }
    var lastTimeObserver: BehaviorSubject<String> { get }
}

class AdapterToken: AdapterTokenProtocol {
    
    let lastTimeObserver: BehaviorSubject<String> = .init(value: "")

    let persistentToken: PersistentToken
    
    var tokenType: Generator.Factor {
        
        return persistentToken.token.generator.factor
    }
    
    var passwordAlgorithm: Generator.Algorithm {
        
        return persistentToken.token.generator.algorithm
    }
    
    let password: BehaviorSubject<String> = .init(value: "")
    
    let name: BehaviorSubject<String> = .init(value: "")
    
    let issuer: BehaviorSubject<String> = .init(value: "")
    
    let refreshTimes: TimeInterval
    
    private var lastTime: TimeInterval {
        
        didSet {
            
            lastTimeObserver.onNext("\(Int(lastTime))")
        }
    }
    
    private var disposeBag: DisposeBag = .init()
    
    init(token: PersistentToken) {
        
        self.persistentToken = token
        
        switch token.token.generator.factor {
            
        case .counter(_):
            
            self.refreshTimes = 0
            
            lastTime = 0
            
            return
            
        case .timer(let period):
          
            self.refreshTimes = period
        }
        
        let now = Date().timeIntervalSince1970
        
        lastTime = TimeInterval(Int(now) % Int(refreshTimes))
        
        lastTime = refreshTimes - lastTime

        let observer = Observable<Int>.interval(RxTimeInterval.seconds(1), scheduler: MainScheduler())
        observer.subscribe(onNext: { [weak self] int in
        
            guard let self = self else { return }

            if self.lastTime == 0 {

                self.lastTime = self.refreshTimes - 1
                self.password.onNext(self.persistentToken.token.currentPassword ?? "")

            } else {

                self.lastTime -= 1
            }
        }).disposed(by: disposeBag)
        
        lastTimeObserver.onNext("\(Int(lastTime))")
        password.onNext(persistentToken.token.currentPassword ?? "")
        name.onNext(persistentToken.token.name)
        issuer.onNext(persistentToken.token.issuer)
    }
}

class KeychainTokenStore {
    
    static let shared: KeychainTokenStore = KeychainTokenStore()
    private let keychain: Keychain
    private let userDefaults: UserDefaults
    let persistentTokensBehavior: BehaviorSubject<[AdapterTokenProtocol]> = .init(value: [])
    private var persistentTokens: [PersistentToken] = [] {
        
        didSet {
            
            persistentTokensBehavior.onNext(persistentTokens.map{ AdapterToken(token: $0) })
        }
    }
    
    private init(keychain: Keychain = Keychain.sharedInstance,
                 userDefaults: UserDefaults = UserDefaults.standard) {
        
        self.keychain = keychain
        self.userDefaults = userDefaults
        
        reloadTokens()
    }
    
    private func reloadTokens() {
        
        let persistentTokenSet = try? keychain.allPersistentTokens()
        let sortedIdentifiers = userDefaults.persistentIdentifiers()

        persistentTokens = persistentTokenSet?.sorted(by: {
            let indexOfA = sortedIdentifiers.firstIndex(of: $0.identifier)
            let indexOfB = sortedIdentifiers.firstIndex(of: $1.identifier)

            switch (indexOfA, indexOfB) {
            case let (.some(iA), .some(iB)) where iA < iB:
                return true
            default:
                return false
            }
        }) ?? []
        
        if persistentTokens.count > sortedIdentifiers.count {
            // If lost tokens were found and appended, save the full list of tokens
            saveTokenOrder()
        }
    }
    
    fileprivate func saveTokenOrder() {
        let persistentIdentifiers = persistentTokens.map { $0.identifier }
        userDefaults.savePersistentIdentifiers(persistentIdentifiers)
    }
}

enum KeyChainTokenError: Error {
    case cannotCreatURL
    case cannotCreatToken
}

extension KeychainTokenStore: TokenStoreProtocol {
    
    func deleteToken(index: Int) throws {
        try deletePersistentToken(persistentTokens[index])
    }
    
    
    func addTokenWith(urlString: String) throws {
        
        guard let url = URL(string: urlString) else {
            
            throw KeyChainTokenError.cannotCreatURL
        }
        
        guard let token = Token(url: url) else {
            
            throw KeyChainTokenError.cannotCreatToken
        }
        try addToken(token)
    }
    
    // MARK: Actions

    func addToken(_ token: Token) throws {
        let newPersistentToken = try keychain.add(token)
        persistentTokens.append(newPersistentToken)
        saveTokenOrder()
    }

    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        let updatedPersistentToken = try keychain.update(persistentToken, with: token)
        // Update the in-memory token, which is still the origin of the table view's data
        
        persistentTokens = persistentTokens.map {
            if $0.identifier == updatedPersistentToken.identifier {
                return updatedPersistentToken
            }
            return $0
        }
    }

    func updatePersistentToken(_ persistentToken: PersistentToken) throws {
        let newToken = persistentToken.token.updatedToken()
        try saveToken(newToken, toPersistentToken: persistentToken)
    }

    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) {
        
        let persistentToken = persistentTokens[origin]
        persistentTokens.remove(at: origin)
        persistentTokens.insert(persistentToken, at: destination)
        saveTokenOrder()
    }

    private func deletePersistentToken(_ persistentToken: PersistentToken) throws {
        try keychain.delete(persistentToken)
        if let index = persistentTokens.firstIndex(of: persistentToken) {
            persistentTokens.remove(at: index)
        }
        saveTokenOrder()
    }
}




// MARK: - Token Order Persistence

private let kOTPKeychainEntriesArray = "KeychainEntries"

private extension UserDefaults {
    func persistentIdentifiers() -> [Data] {
        return array(forKey: kOTPKeychainEntriesArray) as? [Data] ?? []
    }

    func savePersistentIdentifiers(_ identifiers: [Data]) {
        set(identifiers, forKey: kOTPKeychainEntriesArray)
    }
}
