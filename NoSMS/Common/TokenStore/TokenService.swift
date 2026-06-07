import Foundation
import Combine
import OneTimePassword

class TokenService: ObservableObject {
    static let shared = TokenService()
    
    // Reactive properties for SwiftUI views/viewmodels to observe
    @Published var persistentTokens: [PersistentToken] = []
    @Published var pinList: [Data] = []
    @Published var groupList: [GroupObject] = []
    
    // Shared 1-second timer publisher to drive progress rings and password refresh
    let timerPublisher: AnyPublisher<Date, Never>
    
    private let keychain: OneTimePassword.Keychain
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    
    private let kOTPKeychainEntriesArray = "KeychainEntries"
    private let kMustAuthListArray = "kMustAuthListArray"
    private let kMustAuthPinListArray = "kMustAuthPinListArray"
    private let kMustAuthGroupListArray = "kMustAuthGroupListArray"
    
    private init(keychain: OneTimePassword.Keychain = .sharedInstance, userDefaults: UserDefaults = .standard) {
        self.keychain = keychain
        self.userDefaults = userDefaults
        
        // Setup a shared timer that fires every 1.0 second on the main runloop
        self.timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .eraseToAnyPublisher()
            
        loadPinList()
        loadGroupList()
        reloadTokens()
    }
    
    // MARK: - Token Loading & Order
    
    func reloadTokens() {
        let persistentTokenSet = try? keychain.allPersistentTokens()
        var sortedIdentifiers = getPersistentIdentifiers()
        let sortedIdentifiersKeychain = getListSort()
        
        if sortedIdentifiersKeychain.count > sortedIdentifiers.count {
            sortedIdentifiers = sortedIdentifiersKeychain
        }
        
        let allTokens = persistentTokenSet?.sorted(by: {
            let indexOfA = sortedIdentifiers.firstIndex(of: $0.identifier)
            let indexOfB = sortedIdentifiers.firstIndex(of: $1.identifier)

            switch (indexOfA, indexOfB) {
            case let (.some(iA), .some(iB)) where iA < iB:
                return true
            default:
                return false
            }
        }) ?? []
        
        self.persistentTokens = allTokens
        
        if allTokens.count > sortedIdentifiers.count {
            saveTokenOrder()
        }
        if sortedIdentifiers.count > sortedIdentifiersKeychain.count {
            saveTokenOrder()
        }
        if getPersistentIdentifiers().count == 0 {
            saveTokenOrder()
        }
        
        let tokenIDs = allTokens.map({ $0.identifier })
        pinList = checkAndRemovePinForUpdateiOS15(pinList: pinList, tokenIDs: tokenIDs)
        savePinList(data: pinList)
        
        let newFilterGroupList = checkAndRemoveGroupForUpdateiOS15(groupList: groupList, tokenIDs: tokenIDs)
        groupList = newFilterGroupList
        updateGroupList(data: newFilterGroupList)
    }
    
    private func saveTokenOrder() {
        let persistentIdentifiers = persistentTokens.map { $0.identifier }
        savePersistentIdentifiers(persistentIdentifiers)
        updateListSort(data: persistentIdentifiers)
    }
    
    private func getPersistentIdentifiers() -> [Data] {
        return userDefaults.array(forKey: kOTPKeychainEntriesArray) as? [Data] ?? []
    }
    
    private func savePersistentIdentifiers(_ identifiers: [Data]) {
        userDefaults.set(identifiers, forKey: kOTPKeychainEntriesArray)
    }
    
    private func saveListSort(data: [Data]) {
        _ = MustAuthKeychain.keyChainSaveData(data: data, withIdentifier: kMustAuthListArray)
    }
    
    private func updateListSort(data: [Data]) {
        if !MustAuthKeychain.keyChainUpdata(data: data, withIdentifier: kMustAuthListArray) {
            saveListSort(data: data)
        }
    }
    
    private func getListSort() -> [Data] {
        let searchKeyDic = MustAuthKeychain.keyChainReadData(identifier: kMustAuthListArray)
        return searchKeyDic as? [Data] ?? []
    }
    
    // MARK: - Keychain CRUD Operations
    
    func addToken(_ token: Token, groupNames: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        let haveSameToken = persistentTokens.map({ $0.token }).contains(where: {
            $0.name == token.name && $0.issuer == token.issuer
        })
        
        let addClosure = { [weak self] in
            guard let self = self else { return }
            do {
                let newPersistentToken = try self.keychain.add(token)
                self.reloadTokens() // Triggers @Published updates
                
                _ = self.newTokenAddGroups(tokenID: newPersistentToken.identifier, groupsName: groupNames)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
        
        if haveSameToken {
            // Return a specific error or signal that a duplicate exists, so ViewModel can handle alerts
            completion(.failure(NSError(domain: "TokenService", code: 409, userInfo: [
                NSLocalizedDescriptionKey: "此帳號已存在，請確認是否要繼續添加",
                "issuer": token.issuer,
                "name": token.name,
                "retryAction": addClosure
            ])))
        } else {
            addClosure()
        }
    }
    
    func addTokenWith(urlString: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let urlConfirm: URL
        if let url = URL(string: urlString) {
            urlConfirm = url
        } else if let decodeURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: decodeURL) {
            urlConfirm = url
        } else {
            completion(.failure(KeyChainTokenError.cannotCreatURL))
            return
        }
        
        guard let token = Token(customURL: urlConfirm) else {
            completion(.failure(KeyChainTokenError.cannotCreatToken))
            return
        }
        
        guard let groupNames = try? urlConfirm.mustAuth.parsingSetURL().groups else {
            completion(.failure(KeyChainTokenError.groupsError))
            return
        }
        
        addToken(token, groupNames: groupNames, completion: completion)
    }
    
    func saveToken(_ token: Token, toPersistentToken persistentToken: PersistentToken) throws {
        _ = try keychain.update(persistentToken, with: token)
        reloadTokens()
    }
    
    func deleteToken(_ persistentToken: PersistentToken) throws {
        try keychain.delete(persistentToken)
        
        // Clean up from Pin List
        if let pinIndex = pinList.firstIndex(of: persistentToken.identifier) {
            pinList.remove(at: pinIndex)
            updatePinList(data: pinList)
        }
        
        // Clean up from Groups
        var indicesToRemove: [Int] = []
        for index in groupList.indices {
            if let tokenIndex = groupList[index].tokens.firstIndex(of: persistentToken.identifier) {
                groupList[index].tokens.remove(at: tokenIndex)
            }
            if groupList[index].tokens.isEmpty {
                indicesToRemove.append(index)
            }
        }
        indicesToRemove.reverse().forEach { groupList.remove(at: $0) }
        updateGroupList(data: groupList)
        
        reloadTokens()
    }
    
    func moveToken(from source: Int, to destination: Int) {
        guard persistentTokens.indices.contains(source), persistentTokens.indices.contains(destination) else { return }
        
        var updatedTokens = persistentTokens
        let movedToken = updatedTokens.remove(at: source)
        updatedTokens.insert(movedToken, at: destination)
        
        persistentTokens = updatedTokens
        saveTokenOrder()
    }
    
    // MARK: - Pin Management
    
    private func loadPinList() {
        pinList = MustAuthKeychain.keyChainReadData(identifier: kMustAuthPinListArray) as? [Data] ?? []
    }
    
    private func savePinList(data: [Data]) {
        _ = MustAuthKeychain.keyChainSaveData(data: data, withIdentifier: kMustAuthPinListArray)
    }
    
    private func updatePinList(data: [Data]) {
        if !MustAuthKeychain.keyChainUpdata(data: data, withIdentifier: kMustAuthPinListArray) {
            savePinList(data: data)
        }
    }
    
    func tokenAddPin(id: Data) {
        guard !pinList.contains(id) else { return }
        pinList.insert(id, at: 0)
        updatePinList(data: pinList)
        reloadTokens()
    }
    
    func tokenRemovePin(id: Data) {
        guard let index = pinList.firstIndex(of: id) else { return }
        pinList.remove(at: index)
        updatePinList(data: pinList)
        
        if let tokenIndex = persistentTokens.firstIndex(where: { $0.identifier == id }) {
            moveToken(from: tokenIndex, to: 0)
        } else {
            reloadTokens()
        }
    }
    
    private func checkAndRemovePinForUpdateiOS15(pinList: [Data], tokenIDs: [Data]) -> [Data] {
        return pinList.filter({ tokenIDs.contains($0) })
    }
    
    // MARK: - Group Management
    
    private func loadGroupList() {
        let datas = MustAuthKeychain.keyChainReadData(identifier: kMustAuthGroupListArray) as? [Data] ?? []
        let decoder = JSONDecoder()
        groupList = datas.compactMap({ try? decoder.decode(GroupObject.self, from: $0) })
    }
    
    private func updateGroupList(data: [GroupObject]) {
        let encoder = JSONEncoder()
        let saveData = data.compactMap({ try? encoder.encode($0) })
        
        if !MustAuthKeychain.keyChainUpdata(data: saveData, withIdentifier: kMustAuthGroupListArray) {
            _ = MustAuthKeychain.keyChainSaveData(data: saveData, withIdentifier: kMustAuthGroupListArray)
        }
    }
    
    func saveGroup(group: GroupObject) {
        if let index = groupList.firstIndex(where: { $0.uuid == group.uuid }) {
            groupList[index].title = group.title
            groupList[index].tokens = group.tokens
        } else {
            groupList.append(group)
        }
        updateGroupList(data: groupList)
    }
    
    func removeGroup(at index: Int) {
        guard groupList.indices.contains(index) else { return }
        groupList.remove(at: index)
        updateGroupList(data: groupList)
    }
    
    private func checkAndRemoveGroupForUpdateiOS15(groupList: [GroupObject], tokenIDs: [Data]) -> [GroupObject] {
        return groupList.compactMap { group in
            let newGroupTokenIDs = group.tokens.filter({ tokenIDs.contains($0) })
            return newGroupTokenIDs.isEmpty ? nil : GroupObject(title: group.title, uuid: group.uuid, tokens: newGroupTokenIDs)
        }
    }
    
    private func newTokenAddGroups(tokenID: Data, groupsName: [String]) -> Bool {
        guard !groupsName.isEmpty else { return false }
        
        for name in groupsName {
            let matchedGroups = groupList.filter({ $0.title == name })
            if matchedGroups.isEmpty {
                // If group limit of 10 is not exceeded, create new group
                if groupList.count < 10 {
                    let newGroup = GroupObject(title: name, uuid: UUID(), tokens: [tokenID])
                    saveGroup(group: newGroup)
                }
            } else {
                for var group in matchedGroups {
                    if !group.tokens.contains(tokenID) {
                        group.tokens.append(tokenID)
                        saveGroup(group: group)
                    }
                }
            }
        }
        return true
    }
}
