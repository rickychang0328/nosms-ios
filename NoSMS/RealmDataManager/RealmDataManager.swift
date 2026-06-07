//
//  RealmDataManager.swift
//  NoSMS
//
//  Created by Andy LI on 2020/11/5.
//

import Foundation
import RealmSwift

// Plain value type model for SwiftUI / ViewModels (thread-safe, isolates Realm)
struct OTPAccountData: Identifiable, Equatable {
    let id: String
    var account: String
    var time: String
    var issuer: String
    var group: String
    
    init(id: String = UUID().uuidString, account: String = "", time: String = "", issuer: String = "", group: String = "") {
        self.id = id
        self.account = account
        self.time = time
        self.issuer = issuer
        self.group = group
    }
}

// Realm DB Object (Internal to data layer)
class OTPAccount: Object {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var account = ""
    @objc dynamic var time = ""
    @objc dynamic var issuer = ""
    @objc dynamic var group = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class RealmDataManager {
    
    static func addMulitpleShareTokenInRecord(account: String, issuer: String, groups: [String], time: Date, completion: (() -> Void)? = nil) {
        let groupsRemoveDuplicates = groups.removingDuplicates()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = dateFormatter.string(from: time)
        
        var groupString = ""
        for group in groupsRemoveDuplicates {
            groupString += group + " "
        }
        if groupString.isEmpty {
            groupString = "全部"
        }
        
        let finalGroupString = groupString
        
        // Execute write on background thread to ensure thread-safety
        DispatchQueue.global(qos: .background).async {
            autoreleasepool {
                guard let realm = try? Realm() else { return }
                let otpAccount = OTPAccount()
                otpAccount.account = account
                otpAccount.issuer = issuer
                otpAccount.time = timeString
                otpAccount.group = finalGroupString
                
                try? realm.write {
                    realm.add(otpAccount)
                }
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }
    
    // Async/Await version for SwiftUI ViewModels
    static func addMulitpleShareTokenInRecord(account: String, issuer: String, groups: [String], time: Date) async {
        return await withCheckedContinuation { continuation in
            addMulitpleShareTokenInRecord(account: account, issuer: issuer, groups: groups, time: time) {
                continuation.resume()
            }
        }
    }
    
    static func addOTPShareAccount(_ otpToken: AdapterTokenProtocol, time: Date, completion: (() -> Void)? = nil) {
        let accountName = otpToken.token.name
        let issuerName = otpToken.token.issuer
        let uuid = otpToken.uuid
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = dateFormatter.string(from: time)
        
        // Fetch groups and calculate groups string
        var groups = ""
        let groupList = KeychainTokenStore.shared.getGroupList()
        for group in groupList {
            for token in group.tokens {
                if token == uuid {
                    groups += group.title + " "
                }
            }
        }
        if groups.isEmpty {
            groups = "全部"
        }
        
        let finalGroupsString = groups
        
        DispatchQueue.global(qos: .background).async {
            autoreleasepool {
                guard let realm = try? Realm() else { return }
                let otpAccount = OTPAccount()
                otpAccount.account = accountName
                otpAccount.issuer = issuerName
                otpAccount.time = timeString
                otpAccount.group = finalGroupsString
                
                try? realm.write {
                    realm.add(otpAccount)
                }
                
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }
    
    // Async/Await version for SwiftUI ViewModels
    static func addOTPShareAccount(_ otpToken: AdapterTokenProtocol, time: Date) async {
        return await withCheckedContinuation { continuation in
            addOTPShareAccount(otpToken, time: time) {
                continuation.resume()
            }
        }
    }
    
    static func readOTPShareAccount() -> [OTPAccountData] {
        let realm = try! Realm()
        let accounts = realm.objects(OTPAccount.self)
        var accountOTPList = [OTPAccountData]()
        for account in accounts {
            let accountDetail = OTPAccountData(
                id: account.id,
                account: account.account,
                time: account.time,
                issuer: account.issuer,
                group: account.group
            )
            accountOTPList.append(accountDetail)
        }
        return accountOTPList
    }
    
    static func deleteAll(completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            autoreleasepool {
                guard let realm = try? Realm() else { return }
                try? realm.write {
                    realm.deleteAll()
                }
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }
    
    // Async/Await version for SwiftUI ViewModels
    static func deleteAll() async {
        return await withCheckedContinuation { continuation in
            deleteAll {
                continuation.resume()
            }
        }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

