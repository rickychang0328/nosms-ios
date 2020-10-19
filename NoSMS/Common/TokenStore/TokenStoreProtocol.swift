import Foundation
import OneTimePassword
import RxCocoa
import RxSwift

protocol TokenStoreProtocol {
    
    var tokenIsEmpty: Bool { get }
    var tokenList: [AdapterTokenProtocol] { get } 
    var pinEvent: PublishSubject<KeychainTokenStore.PinListEvent> { get }
    var persistentTokensBehavior: BehaviorSubject<[AdapterTokenProtocol]>  { get }
    var haveSelectTokenToDelete: BehaviorSubject<Bool> { get }
 
    func addToken(_ token: Token, groupNames: [String], eventHandler: @escaping (KeychainTokenStore.AddTokenEvent) -> Void)
    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws
    func updatePersistentToken(_ persistentToken: PersistentToken) throws
    func moveTokenFromIndex(_ origin: Int, toIndex destination: Int) throws
    func deleteToken(index: Int) throws
    func addTokenWith(urlString: String, eventHandler: @escaping (KeychainTokenStore.AddTokenEvent) -> Void)
    func resetTokenSelected()
    func deleteSelectedToken() throws
    func mulitpleShareURLAction(urlString: [String], eventHandler: @escaping (KeychainTokenStore.MulitpleShareEvent) -> Void)
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
    var token: Token { get }
    var wantDeleted: BehaviorSubject<Bool> { get }
    var digits: Int { get }
    var isOnTime: Bool { get }
    var getOnTapPassword: () -> Void { get }
    var passwordShow: BehaviorSubject<Bool> { get }
    var isPin: BehaviorSubject<Bool> { get }
    var uuid: Data { get }
    
    func appDidEnterBackgroundReset()
    func resetTimer()
    func changeNewToken(token: Token)
    func addPin()
    func removePin()
    func getMustAuthTokenURL() throws -> URL
}

class AdapterToken: AdapterTokenProtocol {
    
    func addPin() {
        KeychainTokenStore.shared.tokenAddPin(id: uuid)
    }
    
    func removePin() {
        KeychainTokenStore.shared.tokenRemovePin(id: uuid)
    }
    
    var uuid: Data {
        
        return persistentToken.identifier
    }
    
    let isPin: BehaviorSubject<Bool> = .init(value: false)
    
    let passwordShow: BehaviorSubject<Bool> = .init(value: true)
    
    lazy var getOnTapPassword: () -> Void = { [weak self] in
        guard let self = self else { return }
        
        self.token = self.token.updatedToken()
        try? KeychainTokenStore.shared.saveToken(self.token, toPersistentToken: self.persistentToken)
        self.password.onNext(self.token.currentPassword ?? "")
        self.passwordShow.onNext(true)
    }
    
    var token: Token
    
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
    
    func changeNewToken(token: Token) {
        
        self.token = token
    }
    //MARK: 拿 MustAuth 帶有 group 的 URL
    func getMustAuthTokenURL() throws -> URL {
        
        let tokenURL = try token.toURL()
        var urlComponents = URLComponents(url: tokenURL, resolvingAgainstBaseURL: true)
        let baseQuerys = urlComponents?.queryItems ?? []
        let groups = KeychainTokenStore.shared.groupList
        let tokenID = uuid
        let filtergroupsQuery = groups
            .filter({ $0.tokens.contains(tokenID)})
            .map({$0.title})
            .map({URLQueryItem(name: MustAuth.kQueryGroupKey, value: $0)})
        let secret = token.generator.secret.getMustAuthSecret().replacingOccurrences(of: "=", with: "")
        let secretQuery = URLQueryItem(name: MustAuth.kQuerySecretKey, value: secret)
        urlComponents?.queryItems = baseQuerys + filtergroupsQuery + [secretQuery]
        urlComponents?.scheme = MustAuth.kMustAuthScheme
        guard let result = urlComponents?.url else {
            
            throw NoSMSError.urlError
        }
        return result
    }
}

class KeychainTokenStore {
    
    let groupListBehavior: BehaviorSubject<[GroupObject]> = .init(value: [])
    
    let pinEvent: PublishSubject<KeychainTokenStore.PinListEvent> = .init()
    
    enum AddTokenEvent {
        
        case addSuccess
        case haveTheSame(title: String, message: String, completion: () -> Void)
        case addError(Error)
    }
    
    var pinList: [Data] = []
    
    var groupList: [GroupObject] = []
    
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
        getPinListInKeyChain()
        getGroupListInKeyChain()
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
                               
                    nameArray[index]
                        .filter({$0.count <= MustAuth.issuerAndAccountLimit})
                        .subscribe(onNext: { newName in
                                   
                        if self.persistentTokens[index].token.name != newName {
                            
                            let generator = tokenArray[index].token.generator
                            let issuer = tokenArray[index].token.issuer
                            let newToken = Token(name: newName, issuer: issuer, generator: generator)
                            
                            try? self.saveToken(newToken, toPersistentToken: tokenArray[index].persistentToken)
                            tokenArray[index].changeNewToken(token: newToken)
                        }
                    }).disposed(by: self.disposeBag)
                }
                
                let issuerArray = tokenArray.map({$0.issuer})
                
                for index in issuerArray.indices {
                    
                    issuerArray[index]
                        .filter({$0.count <= MustAuth.issuerAndAccountLimit})
                        .subscribe(onNext: { newIssuer in
                        
                        if self.persistentTokens[index].token.issuer != newIssuer {
                            
                            let generator = tokenArray[index].token.generator
                            let name = tokenArray[index].token.name
                            let newToken = Token(name: name, issuer: newIssuer, generator: generator)
                            
                            try? self.saveToken(newToken, toPersistentToken: tokenArray[index].persistentToken)
                            tokenArray[index].changeNewToken(token: newToken)
                        }
                    }).disposed(by: self.disposeBag)
                }
            })
    }
    
    private func reloadTokens() {
        
        let persistentTokenSet = try? keychain.allPersistentTokens()
        var sortedIdentifiers = userDefaults.persistentIdentifiers()
        let sortedIdentifiersKeychain = getListSort()
        
        // 刪掉 app 的邏輯
        if sortedIdentifiersKeychain.count > sortedIdentifiers.count {
            
            sortedIdentifiers = sortedIdentifiersKeychain
        }
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
        
        // 新增 keychain 的排序
        if sortedIdentifiers.count > sortedIdentifiersKeychain.count {
            
            saveTokenOrder()
        }
        
        if userDefaults.persistentIdentifiers().count == 0 {
            
            saveTokenOrder()
        }
    }
    
    fileprivate func saveTokenOrder() {
        let persistentIdentifiers = persistentTokens.map { $0.identifier }
        userDefaults.savePersistentIdentifiers(persistentIdentifiers)
        updateListSort(data: persistentIdentifiers)
    }
}

enum KeyChainTokenError: Error {
    case cannotCreatURL
    case cannotCreatToken
    case groupsError
}

extension KeychainTokenStore: TokenStoreProtocol {
 
    var tokenIsEmpty: Bool {
        
        return adapterTokens.isEmpty
    }
    
    var tokenList: [AdapterTokenProtocol]  {
           
        return adapterTokens
    }
    
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
        
        //中文坑 可能需要轉碼 但如果轉過碼又轉一次會爆
        let urlComfirm: URL
        
        if let url = URL(string: urlString) {
            
            urlComfirm = url
        } else if let decodeURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: decodeURL) {
            
            urlComfirm = url
        } else {
            
            eventHandler(.addError(KeyChainTokenError.cannotCreatURL))
            return
        }
        
        guard let token = Token(customURL: urlComfirm) else {
            
            eventHandler(.addError(KeyChainTokenError.cannotCreatToken))
            return
        }
        
        guard let groupNames = try? urlComfirm.mustAuth.parsingSetURL().groups else {
            
            eventHandler(.addError(KeyChainTokenError.groupsError))
            return
        }
        
        addToken(token, groupNames: groupNames, eventHandler: eventHandler)
    }
    
    // MARK: Actions

    func addToken(_ token: Token, groupNames: [String], eventHandler: @escaping (AddTokenEvent) -> Void) {
        
        let haveSameToken = persistentTokens.map({$0.token}).contains(where: {$0.name == token.name && $0.issuer == token.issuer})
        
        let addTokenHalder: () -> Void = {
            
            do {
                try self.addTokenSure(token, groupNames: groupNames)
                eventHandler(.addSuccess)

            } catch {
                
                eventHandler(.addError(KeyChainTokenError.cannotCreatToken))
            }
        }
        
        if haveSameToken {
            
            eventHandler(.haveTheSame(title: "此帐号已存在，请确认是否要继续添加", message: "[ \(token.issuer) ] \(token.name)", completion: addTokenHalder))
        } else {
            
            addTokenHalder()
        }
    }
    
    private func addTokenSure(_ token: Token, groupNames: [String]) throws {
        
        let newPersistentToken = try keychain.add(token)
        persistentTokens.append(newPersistentToken)
        let adapterToken = AdapterToken(persistentToken: newPersistentToken, observerTimer: timerObserver)
        adapterTokens.append(adapterToken)
        persistentTokensBehavior.onNext(adapterTokens)
        adapterToken.passwordShow.onNext(true)
        resetTimer()
        saveTokenOrder()
        newTokenAddGroups(tokenID: newPersistentToken.identifier, groupsName: groupNames)
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
        
        var removeGroupList: [Int] = []
        
        for index in groupList.indices {
            
            if let tokenIndex = groupList[index].tokens.firstIndex(where: {$0 == persistentToken.identifier}) {
                
                groupList[index].tokens.remove(at: tokenIndex)
            }
            
            if groupList[index].tokens.isEmpty {
                
                removeGroupList.append(index)
            }
        }
        
        removeGroupList.reverse()
        
        for removeIndex in removeGroupList {
            
            groupList.remove(at: removeIndex)
        }
        
        persistentTokensBehavior.onNext(adapterTokens)
        updateGroipList(data: groupList)
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
    
    func getAllSameTokens(name: String, issuer: String) -> [AdapterTokenProtocol] {
        
        return adapterTokens.filter({($0.token.name == name) && ($0.token.issuer == issuer) })

    }

    func getSameTokensWithType(name: String, issuer: String, isOnTime: Bool) -> [AdapterTokenProtocol] {
        
        return getAllSameTokens(name: name, issuer: issuer).filter({$0.isOnTime == isOnTime})
    }
    
    
    enum MulitpleShareEvent {
        
        case success(toast: String)
        case haveSameToken(message: String, replaceHandler: () -> Void, newAddHandler: () -> Void)
        case error(error: Error)
    }
    
    private class MulitpleShareToken {
        
        var token: Token
        let groupNames: [String]
        var isAdded: Bool = false
        
        internal init(token: Token, groupNames: [String]) {
            self.token = token
            self.groupNames = groupNames
        }
        
        func changeNamePlus(index: String) {
            
            token = Token(name: token.name + index, issuer: token.issuer, generator: token.generator)
        }
    }
    
    func mulitpleShareURLAction(urlString: [String], eventHandler: @escaping (MulitpleShareEvent) -> Void) {
        
        let mulitpleShareTokens = urlString.compactMap({ (url) -> MulitpleShareToken? in
            
            guard let tokenURL = try? url.mustAuth.parsingSetURL() else { return nil }
            guard let token = Token(customURL: tokenURL.url) else { return nil }
            let group = tokenURL.groups
            let result = MulitpleShareToken(token: token, groupNames: group)
            return result
        })
        
        guard mulitpleShareTokens.count == urlString.count else {
            
            eventHandler(.error(error: NoSMSError.urlError))
            return
        }
        
        let sameTokens = mulitpleShareTokens.map({self.getSameTokensWithType(name: $0.token.name, issuer: $0.token.issuer, isOnTime: $0.token.isOnTime)}).flatMap({$0})
        
        let dontHaveSame = sameTokens.isEmpty
        
        let mulitpleShareNewSaveHandler = {
            
            for mulitpleShareToken in mulitpleShareTokens {
                
                do {
                    if mulitpleShareToken.isAdded {
                        
                    } else {
                        
                        try self.addTokenSure(mulitpleShareToken.token, groupNames: mulitpleShareToken.groupNames)
                    }
                } catch {
                    
                    eventHandler(.error(error: error))
                    return
                }
            }
            let toast = "已导入\(mulitpleShareTokens.count)个验证码"
            eventHandler(.success(toast: toast))
            let shareRecordManager = ShareRecordStoreManager()
            shareRecordManager.addNewRecord(description: "导入：\(mulitpleShareTokens.count)个验证码")
        }
        
        if dontHaveSame {
            
            mulitpleShareNewSaveHandler()
        } else {
                        
            let newAddHandler = {
                
                for sameToken in sameTokens {
                    
                    let filterToken = mulitpleShareTokens.filter({ $0.token.name == sameToken.token.name && $0.token.issuer == sameToken.token.issuer && $0.token.isOnTime == sameToken.isOnTime})
                    
                    for index in filterToken.indices {
                        
                        filterToken[index].changeNamePlus(index: "\(index + 1)")
                    }
                }
                mulitpleShareNewSaveHandler()
            }
            let replaceHandler = {
                
                for mulitpleShareToken in mulitpleShareTokens {
                    
                    let sameTokens = sameTokens.filter({ $0.token.name == mulitpleShareToken.token.name && $0.token.issuer == mulitpleShareToken.token.issuer && $0.token.isOnTime == mulitpleShareToken.token.isOnTime })
                    
                    let samePersistentTokens = sameTokens.map({ $0.persistentToken })
                    for samePersistentToken in samePersistentTokens {
                        
                        do {
                            
                            try self.saveToken(mulitpleShareToken.token, toPersistentToken: samePersistentToken)
                            mulitpleShareToken.isAdded = true
                        } catch {
                            
                            eventHandler(.error(error: error))
                            return
                        }
                    }
                }
                mulitpleShareNewSaveHandler()
            }
            
            var filterTokens: [KeychainTokenStore.MulitpleShareToken] = []
            
            for sameToken in sameTokens {
                
                let filterToken = mulitpleShareTokens.filter({ $0.token.name == sameToken.token.name && $0.token.issuer == sameToken.token.issuer && $0.token.isOnTime == sameToken.isOnTime})
                
                if filterTokens.contains(where: { $0.token.name == sameToken.token.name && $0.token.issuer == sameToken.token.issuer && $0.token.isOnTime == sameToken.isOnTime }) {
                    
                } else {
                    
                    filterTokens += filterToken
                }
            }
            
            var message: String = ""
            
            for index in filterTokens.indices {
                
                if index == 0 {
                    message += "[\(filterTokens[index].token.issuer)] \(filterTokens[index].token.name)".clipTextWithDot(width: NoSMSAlertThreeButtonView.messageWidth, font: NoSMSAlertThreeButtonView.messageFont)
                    
                } else if index > 2 {
                    
                    message += "\n..."
                    break
                } else {
                    message += "\n"
                    message += "[\(filterTokens[index].token.issuer)] \(filterTokens[index].token.name)".clipTextWithDot(width: NoSMSAlertThreeButtonView.messageWidth, font: NoSMSAlertThreeButtonView.messageFont)
                }
            }
            
            eventHandler(.haveSameToken(message: message, replaceHandler: replaceHandler, newAddHandler: newAddHandler))
        }
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


// MARK: KeyChain
private let kMustAuthListArray = "kMustAuthListArray"
private let kMustAuthPinListArray = "kMustAuthPinListArray"
private let kMustAuthGroupListArray = "kMustAuthGroupListArray"


class MustAuthKeychain {
    
    class func createQuaryMutableDictionary(identifier:String)->NSMutableDictionary{
        // 创建一个条件字典
        let keychainQuaryMutableDictionary = NSMutableDictionary.init(capacity: 0)
        // 设置条件存储的类型
        keychainQuaryMutableDictionary.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        // 设置存储数据的标记
        keychainQuaryMutableDictionary.setValue(identifier, forKey: kSecAttrService as String)
        keychainQuaryMutableDictionary.setValue(identifier, forKey: kSecAttrAccount as String)
        // 设置数据访问属性
        keychainQuaryMutableDictionary.setValue(kSecAttrAccessibleAfterFirstUnlock, forKey: kSecAttrAccessible as String)
        // 返回创建条件字典
        return keychainQuaryMutableDictionary
    }
    
    // TODO: 存储数据
    class func keyChainSaveData(data: Any ,withIdentifier identifier:String)-> Bool {
        // 获取存储数据的条件
        let keyChainSaveMutableDictionary = self.createQuaryMutableDictionary(identifier: identifier)
        // 删除旧的存储数据
        SecItemDelete(keyChainSaveMutableDictionary)
        // 设置数据
        keyChainSaveMutableDictionary.setValue(NSKeyedArchiver.archivedData(withRootObject: data), forKey: kSecValueData as String)
        // 进行存储数据
        let saveState = SecItemAdd(keyChainSaveMutableDictionary, nil)
        if saveState == noErr  {
            return true
        }
        return false
    }

    // TODO: 更新数据
    class func keyChainUpdata(data:Any ,withIdentifier identifier:String) -> Bool {
        // 获取更新的条件
        let keyChainUpdataMutableDictionary = self.createQuaryMutableDictionary(identifier: identifier)
        // 创建数据存储字典
        let updataMutableDictionary = NSMutableDictionary.init(capacity: 0)
        // 设置数据
        updataMutableDictionary.setValue(NSKeyedArchiver.archivedData(withRootObject: data), forKey: kSecValueData as String)
        // 更新数据
        let updataStatus = SecItemUpdate(keyChainUpdataMutableDictionary, updataMutableDictionary)
        if updataStatus == noErr {
            return true
        }
        return false
    }
    
    
    // TODO: 获取数据
    class func keyChainReadData(identifier:String) -> Any {
        var idObject:Any?
        // 获取查询条件
        let keyChainReadmutableDictionary = self.createQuaryMutableDictionary(identifier: identifier)
        // 提供查询数据的两个必要参数
        keyChainReadmutableDictionary.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        keyChainReadmutableDictionary.setValue(kSecMatchLimitOne, forKey: kSecMatchLimit as String)
        // 创建获取数据的引用
        var queryResult: AnyObject?
        // 通过查询是否存储在数据
        let readStatus = withUnsafeMutablePointer(to: &queryResult) { SecItemCopyMatching(keyChainReadmutableDictionary, UnsafeMutablePointer($0))}
        if readStatus == errSecSuccess {
            if let data = queryResult as! NSData? {
                idObject = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as Any
            }
        }
        return idObject as Any
    }
    
    // TODO: 删除数据
    class func keyChianDelete(identifier:String)->Void{
        // 获取删除的条件
        let keyChainDeleteMutableDictionary = self.createQuaryMutableDictionary(identifier: identifier)
        // 删除数据
        SecItemDelete(keyChainDeleteMutableDictionary)
    }
}



//MARK: TokenKeychainCRUD
extension KeychainTokenStore {
    
    private func saveListSort(data: [Data]) {
        
        _ = MustAuthKeychain.keyChainSaveData(data: data, withIdentifier: kMustAuthListArray)
    }
    
    private func updateListSort(data: [Data]) {
        
        let updateSuccess = MustAuthKeychain.keyChainUpdata(data: data, withIdentifier: kMustAuthListArray)
        
        if updateSuccess {
            
            
        } else {
            
            saveListSort(data: data)
        }
        
    }
    
    private func getListSort() -> [Data] {
        
        let seachKeyDic = MustAuthKeychain.keyChainReadData(identifier: kMustAuthListArray)
        
        return seachKeyDic as? [Data] ?? []
    }
    
    private func savePinList(data: [Data]) {
           
        _ = MustAuthKeychain.keyChainSaveData(data: data, withIdentifier: kMustAuthPinListArray)
    }
       
    private func updatePinList(data: [Data]) {
           
        let updateSuccess = MustAuthKeychain.keyChainUpdata(data: data, withIdentifier: kMustAuthPinListArray)
           
        if updateSuccess {
               
               
        } else {
               
            savePinList(data: data)
        }
    }
    private func getPinListInKeyChain() {
        
        pinList = MustAuthKeychain.keyChainReadData(identifier: kMustAuthPinListArray) as? [Data] ?? []
    }
    
    func tokenAddPin(id: Data) {
        
        pinList = [id] + pinList
        updatePinList(data: pinList)
        pinEvent.onNext(.addPin(id: id))
    }
    
    func tokenRemovePin(id: Data) {
        
        let tokenIndexInPin = pinList.firstIndex(where: { $0 == id}) ?? 0
        pinList.remove(at: tokenIndexInPin)
        updatePinList(data: pinList)
        
        let tokenIndex = persistentTokens.firstIndex(where: { $0.identifier == id}) ?? 0
        
        moveTokenFromIndex(tokenIndex, toIndex: 0)
        pinEvent.onNext(.remove(id: id))

    }
    
    func getPinList() -> [Data] {
     
        return pinList
    }
    
    enum PinListEvent {
        
        case emtpy
        case addPin(id: Data)
        case remove(id: Data)
    }
}

//MARK: Group

struct GroupObject: Codable {
    
    var title: String
    let uuid: UUID
    var tokens: [Data]
    
    internal init(title: String, uuid: UUID, tokens: [Data]) {
        self.title = title
        self.uuid = uuid
        self.tokens = tokens
    }
    
    init() {
        
        self.title = ""
        self.uuid = UUID()
        self.tokens = []
    }
}

extension KeychainTokenStore {
    
    var canAddGroup: Observable<Bool> {
        
        return groupListBehavior.map({!($0.count >= self.groupMax)}).asObservable()
    }
    
    private var groupMax: Int { return 10 }
    
    private func saveGroupList(data: [Data]) {
        
        _ = MustAuthKeychain.keyChainSaveData(data: data, withIdentifier: kMustAuthGroupListArray)
    }
       
    private func updateGroipList(data: [GroupObject]) {
        
        let encoder = JSONEncoder()

        let saveData = data.compactMap({
            
            return try? encoder.encode($0)
        })
        
        let updateSuccess = MustAuthKeychain.keyChainUpdata(data: saveData, withIdentifier: kMustAuthGroupListArray)
           
        if updateSuccess {
               
               
        } else {
               
            saveGroupList(data: saveData)
        }
        
        groupListBehavior.onNext(groupList)
    }
    private func getGroupListInKeyChain() {
        
        
        let datas = MustAuthKeychain.keyChainReadData(identifier: kMustAuthGroupListArray) as? [Data] ?? []
        let decoder = JSONDecoder()
        
        groupList = datas.compactMap({
            return try? decoder.decode(GroupObject.self, from: $0)})
        
        groupListBehavior.onNext(groupList)
    }
    
    func saveGroup(groupID: GroupObject) {
        
        if let groupIndex = groupList.firstIndex(where: { $0.uuid == groupID.uuid }) {
            
            groupList[groupIndex].title = groupID.title
            groupList[groupIndex].tokens = groupID.tokens
        } else {
            
            groupList.append(groupID)
        }
        
        updateGroipList(data: groupList)
    }
    
    func removeGroup(index: Int) {
        
        groupList.remove(at: index)
        updateGroipList(data: groupList)
    }
    
    func getGroupList() -> [GroupObject] {
     
        return groupList
    }
    
    func getGroup(uuid: UUID) -> GroupObject? {
        
        return groupList.first(where: { $0.uuid == uuid})
    }
    
    func getGroups(name: String) -> [GroupObject] {
        
        return groupList.filter({ $0.title == name })
    }
    
    func newTokenAddGroups(tokenID: Data, groupsName: [String]) {
        
        if groupsName.isEmpty {
            
            return
        }
        
        for groupName in groupsName {
            
            let groups = getGroups(name: groupName)
            
            if groups.isEmpty {
                
                var newGroup = GroupObject()
                newGroup.title = groupName
                newGroup.tokens.append(tokenID)
                saveGroup(groupID: newGroup)
            } else {
                
                for var group in groups {
                    
                    group.tokens.append(tokenID)
                    saveGroup(groupID: group)
                }
            }
        }
    }
    
    func moveGroup(_ origin: Int, toIndex destination: Int) {
        
        let group = groupList[origin]
        groupList.remove(at: origin)
        groupList.insert(group, at: destination)
        updateGroipList(data: groupList)
    }
}
