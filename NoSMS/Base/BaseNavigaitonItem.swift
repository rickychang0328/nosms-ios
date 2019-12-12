//
//  BaseNavigaitonItem.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/25.
//

import Foundation
import RxCocoa
import RxSwift

protocol BaseNavigaitonItemProtocol {
    
    var title: BehaviorSubject<String> { get }
}

struct BaseNavigaitonItem: BaseNavigaitonItemProtocol {
    
    let title: BehaviorSubject<String>
}
