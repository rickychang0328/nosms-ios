import Foundation
import OneTimePassword
import RxCocoa
import RxSwift

protocol TokenStoreProtocol {
    
    var persistentTokensBehavior: BehaviorSubject<[AdapterTokenProtocol]>  { get }
    var haveSelectTokenToDelete: BehaviorSubject<Bool> { get }
 
    func addToken(_ token: Token, eventHandler: @escaping (KeychainTokenStore.AddTokenEvent) -> Void)
    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws
    func updatePersistentToken(_ persistentToken: PersistentToken) throws
    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) throws
    func deleteToken(index: Int) throws
    func addTokenWith(urlString: String, eventHandler: @escaping (KeychainTokenStore.AddTokenEvent) -> Void)
    func resetTokenSelected()
    func deleteSelectedToken() throws
}

protocol AdapterTokenProtocol {
    
    var tokenType: Generator.Factor { get }
    var passwordAlgorithm: Generator.Algorithm { get }
    var password: BehaviorSubject<String> { get }
    var name: BehaviorSubject<String>  { get }
    var issuer: BehaviorSubject<String>  { get }
    var refreshTimes: TimeInterval { get }
    var lastTimeObserver: BehaviorSubject<String> { get }
    var persistentToken: PersistentToken { get }
    var wantDeleted: BehaviorSubject<Bool> { get }
    var digits: Int { get }
    var isOnTime: Bool { get }
    var getOnTapPassword: () -> Void { get }
    var passwordShow: BehaviorSubject<Bool> { get }
    
    func appDidEnterBackgroundReset()
    func resetTimer()
}

class AdapterToken: AdapterTokenProtocol {

    let passwordShow: BehaviorSubject<Bool> = .init(value: true)
    
    lazy var getOnTapPassword: () -> Void = { [weak self] in
        guard let self = self else { return }
        
        self.token = self.token.updatedToken()
        try? KeychainTokenStore.shared.saveToken(self.token, toPersistentToken: self.persistentToken)
        self.password.onNext(self.token.currentPassword ?? "")
        self.passwordShow.onNext(true)
    }
    
    private var token: Token
    
    var isOnTime: Bool {
        
        switch tokenType {
            
        case .counter:
            
            return false
        case .timer:
            
            return true
        }
    }

    var digits: Int {
        
        return persistentToken.token.generator.digits
    }

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
    
    let wantDeleted: BehaviorSubject<Bool> = .init(value: false)
    
    private var lastTime: TimeInterval {
        
        didSet {
            
            lastTimeObserver.onNext("\(Int(lastTime))")
        }
    }
    
    private var disposeBag: DisposeBag = .init()
    
    private let timer: Observable<TimeInterval>
    
    init(persistentToken: PersistentToken, observerTimer: Observable<TimeInterval>) {
        
        self.persistentToken = persistentToken
        self.token = persistentToken.token
        
        name.onNext(persistentToken.token.name)
        issuer.onNext(persistentToken.token.issuer)
        password.onNext(persistentToken.token.currentPassword ?? "")
        lastTime = 0

        self.timer = observerTimer
        switch persistentToken.token.generator.factor {

        case .counter(_):
            
            self.refreshTimes = 0
            
            passwordShow.onNext(false)
            return
            
        case .timer(let period):
            
            self.refreshTimes = period
            resetTimer()
        }
    }
    
    func resetTimer() {
        
        if !isOnTime {
            
            return
        }
        
        disposeBag = .init()
        
        let now = Date().timeIntervalSince1970
        
        let lastTimeReverse = TimeInterval(Int(now) % Int(refreshTimes))
            
        password.onNext(persistentToken.token.currentPassword ?? "")
        
        self.lastTime = self.refreshTimes - lastTimeReverse - 1

        timer.subscribe(onNext: { [weak self] now in
            guard let self = self else { return }
            let lastTimeReverse = TimeInterval(Int(now) % Int(self.refreshTimes))
            
            if lastTimeReverse == 0 {
                

                self.password.onNext(self.persistentToken.token.currentPassword ?? "")
            } else {

            }
            self.lastTime = self.refreshTimes - lastTimeReverse - 1


        }).disposed(by: disposeBag)
    }
    
    func appDidEnterBackgroundReset() {
        
        switch tokenType {
        case .counter:
            passwordShow.onNext(false)
        case .timer:
            break
        }
    }
}

class KeychainTokenStore {
    
    enum AddTokenEvent {
        
        case addSuccess
        case haveTheSame(title: String, message: String, completion: () -> Void)
        case addError(Error)
    }
    
    let haveSelectTokenToDelete: BehaviorSubject<Bool> = .init(value: false)
    
    static let shared: KeychainTokenStore = KeychainTokenStore()
    private let keychain: Keychain
    private let userDefaults: UserDefaults
    let persistentTokensBehavior: BehaviorSubject<[AdapterTokenProtocol]> = .init(value: [])
    
    var adapterTokens: [AdapterTokenProtocol] = []
    
    private var persistentTokens: [PersistentToken] = []
    
    private func checkDelete() {
        
        guard let array = try? persistentTokensBehavior.value().compactMap({ try? $0.wantDeleted.value()}) else { return }
        
        let result = array.contains(true)
        
        haveSelectTokenToDelete.onNext(result)
    }
    
    func resetTokenSelected() {
        
        guard let array = try? persistentTokensBehavior.value().map({$0.wantDeleted}) else { return }
               
        array.forEach {
            
            $0.onNext(false)
        }
    }
    
    
    private var disposeBag: DisposeBag = .init()
    
    private let timerObserver: Observable<TimeInterval> = BehaviorSubject<Int>.interval(RxTimeInterval.seconds(1), scheduler: ConcurrentMainScheduler.instance).map({ _ in return Date().timeIntervalSince1970})
    private init(keychain: Keychain = Keychain.sharedInstance,
                 userDefaults: UserDefaults = UserDefaults.standard) {
        
        self.keychain = keychain
        self.userDefaults = userDefaults
        
        reloadTokens()
        
        // 刪除 token 邏輯
        _ = persistentTokensBehavior
            .subscribe(onNext: { tokenArray in
                self.disposeBag = .init()
                
                let wantToDeleteArray = tokenArray.map({$0.wantDeleted})
                wantToDeleteArray.forEach {
                    
                    $0.subscribe(onNext: { _ in
                        
                        self.checkDelete()
                    }).disposed(by: self.disposeBag)
                }
                
                
                //更改名字邏輯
                let nameArray = tokenArray.map({$0.name})
                
                for index in nameArray.indices {
                               
                    nameArray[index].subscribe(onNext: { newName in
                                   
                        if self.persistentTokens[index].token.name != newName {
                            
                            let generator = tokenArray[index].persistentToken.token.generator
                            
                            let issuer = tokenArray[index].persistentToken.token.issuer
                            try? self.saveToken(Token(name: newName, issuer: issuer, generator: generator), toPersistentToken: tokenArray[index].persistentToken)
                        }
                    }).disposed(by: self.disposeBag)
                }
            })
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
        
        adapterTokens = persistentTokens.map{ AdapterToken(persistentToken: $0, observerTimer: timerObserver) }
        persistentTokensBehavior.onNext(adapterTokens)

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
    
    func deleteSelectedToken() throws {
        
        guard let array = try? persistentTokensBehavior.value().compactMap({ try? $0.wantDeleted.value()}) else { return }
        
        var indexArray: [Int] = []
        
        for index in array.indices {
            
            if array[index] {
                
                indexArray.append(index)
            }
        }
        
        indexArray.reverse()
        
        try indexArray.forEach {
            
            try deleteToken(index: $0)
        }
        
        persistentTokensBehavior.onNext(adapterTokens)
    }
    
    func addTokenWith(urlString: String, eventHandler: @escaping (AddTokenEvent) -> Void) {
        
        guard let url = URL(string: urlString) else {
            
            eventHandler(.addError(KeyChainTokenError.cannotCreatURL))
            return
        }
        
        guard let token = Token(url: url) else {
            
            eventHandler(.addError(KeyChainTokenError.cannotCreatToken))
            return
        }
        addToken(token, eventHandler: eventHandler)
    }
    
    // MARK: Actions

    func addToken(_ token: Token, eventHandler: @escaping (AddTokenEvent) -> Void) {
        
        let haveSameToken = persistentTokens.map({$0.token}).contains(where: {$0.name == token.name && $0.issuer == token.issuer})
        
        if haveSameToken {
            
            eventHandler(.haveTheSame(title: "此帐号已存在，请确认是否要继续添加", message: "[ \(token.issuer) ] \(token.name)", completion: {
                do {
                    try self.addTokenSure(token)
                    eventHandler(.addSuccess)

                } catch {
                    
                    eventHandler(.addError(KeyChainTokenError.cannotCreatToken))
                }
            }))
        } else {
            
            do {
                try self.addTokenSure(token)
                eventHandler(.addSuccess)

            } catch {
                
                eventHandler(.addError(KeyChainTokenError.cannotCreatToken))
            }
        }
    }
    
    private func addTokenSure(_ token: Token) throws {
        
        let newPersistentToken = try keychain.add(token)
        persistentTokens.append(newPersistentToken)
        let adapterToken = AdapterToken(persistentToken: newPersistentToken, observerTimer: timerObserver)
        adapterTokens.append(adapterToken)
        persistentTokensBehavior.onNext(adapterTokens)
        adapterToken.passwordShow.onNext(true)
        resetTimer()
        saveTokenOrder()
    }

    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        _ = try keychain.update(persistentToken, with: token)
    }

    func updatePersistentToken(_ persistentToken: PersistentToken) throws {
        let newToken = persistentToken.token.updatedToken()
        try saveToken(newToken, toPersistentToken: persistentToken)
    }

    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) {
        
        let persistentToken = persistentTokens[origin]
        persistentTokens.remove(at: origin)
        persistentTokens.insert(persistentToken, at: destination)
        
        let adapterToken = adapterTokens[origin]
        adapterTokens.remove(at: origin)
        adapterTokens.insert(adapterToken, at: destination)
        
        persistentTokensBehavior.onNext(adapterTokens)
        saveTokenOrder()
    }

    private func deletePersistentToken(_ persistentToken: PersistentToken) throws {
        try keychain.delete(persistentToken)
        if let index = persistentTokens.firstIndex(of: persistentToken) {
            persistentTokens.remove(at: index)
        }
        if let index = adapterTokens.firstIndex(where: {$0.persistentToken == persistentToken}) {
            
            adapterTokens.remove(at: index)
        }
        
        persistentTokensBehavior.onNext(adapterTokens)
        saveTokenOrder()
    }
    
    func appDidEnterBackgroundResetting() {
        
        adapterTokens.forEach({ $0.appDidEnterBackgroundReset() })
    }
    
    func appWillEnterForeground () {
        
        resetTimer()
    }
    
    private func resetTimer() {
        
        adapterTokens.forEach({$0.resetTimer()})
    }
    
    func getSameTokens(name: String, issuer: String) -> [AdapterTokenProtocol] {
        
        return adapterTokens.filter({($0.persistentToken.token.name == name) && ($0.persistentToken.token.issuer == issuer) })
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
