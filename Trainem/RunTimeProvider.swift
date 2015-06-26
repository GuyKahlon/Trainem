//
//  RunTimeProvider.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/24/15.
//  Copyright © 2015 GuyKahlon. All rights reserved.
//

import Foundation

enum UserType:String {
    case Trainee = "Trainee"
    case Coach = "Coach"
    
    static func toUserType(userStringType: String) -> UserType? {
        switch userStringType {
            case Trainee.rawValue:
                return .Trainee
            case Coach.rawValue:
                return .Coach
            default: return nil //TODO - Print error , The defualt is .Traine judt from security resonse

        }
    }
}

class RunTimeProvider{
    
    let user: UserType
    
    init(userType: UserType){
        user = userType
    }
}