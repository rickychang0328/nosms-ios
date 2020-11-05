//
//  File.swift
//  NoSMS
//
//  Created by Andy LI on 2020/11/5.
//

import Foundation
import RealmSwift

class RealmDataManager {
    
    static func addMulitpleShareTokenInRecord(account: String, issuer: String, groups: [String] ,time: Date) {
        
        let groupsRemoveDuplicates = groups.removingDuplicates()
        let realm = try! Realm()
        let otpAccount: OTPAccount = OTPAccount()
        otpAccount.account = account
        otpAccount.issuer = issuer
        let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = dateFormatter.string(from: time)
        otpAccount.time = time
        var groupString = ""
        for group in groupsRemoveDuplicates {
            
            groupString += group + " "
        }
        if groupString == "" {
            groupString = "全部"
        }
        otpAccount.group = groupString
        try! realm.write {
            realm.add(otpAccount)
        }
    }
    
    static func addOTPShareAccount(_ otpToken: AdapterTokenProtocol, time: Date) {
        let realm = try! Realm()
        let otpAccount: OTPAccount = OTPAccount()
        otpAccount.account = otpToken.token.name
        otpAccount.issuer = otpToken.token.issuer
        let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = dateFormatter.string(from: time)
        otpAccount.time = time
        var groups = ""
        let groupList = KeychainTokenStore.shared.getGroupList()
        for group in groupList {
            for token in group.tokens {
                if token == otpToken.uuid {
                    groups += group.title + " "
                }
            }
        }
        if groups == "" {
            groups = "全部"
        }
        otpAccount.group = groups
        try! realm.write {
            realm.add(otpAccount)
        }
        print("fileURL: \(realm.configuration.fileURL!)")
    }
    
    static func readOTPShareAccount() -> [OTPAccountData] {
        let realm = try! Realm()
        let accounts = realm.objects(OTPAccount.self)
        var accountOTPList = [OTPAccountData]()
        for account in accounts {
            let accountDetail = OTPAccountData()
            accountDetail.account = account.account
            accountDetail.group = account.group
            accountDetail.time = account.time
            accountDetail.issuer = account.issuer
            accountOTPList.append(accountDetail)
        }
        return accountOTPList.reversed()
    }
    
    static func deleteAll() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
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
