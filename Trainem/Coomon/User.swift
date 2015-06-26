//
//  User.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/19/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation

//enum UserType: Int {
//    case Trainee, Coach
//}

class UserFactory {
    
//    class func UserForEnvironment(runTimeProvider:RunTimeProvider) -> User {
//        
//        switch runTimeProvider.user {
//        case .Trainee:
//            return Cocah()
//        case .Coach:
//            return Trainee()
//        }
//    }
    
    private static var currentUser:User?
    
    class func getCurrentUser() -> User?{
        
        if let user = currentUser{
            return user
        }
        else if let user = PFUser.currentUser()
        {
           if let userTypeString = user[UserProprtiesKey.UserType] as? String,
              let userType = UserType.toUserType(userTypeString){
        
                switch userType{
                    case .Trainee:
                        currentUser = Trainee()
                        //NSLog("Trainee")
                    case .Coach:
                        currentUser = Cocah()
                        //NSLog("Cocah")
                }
            }
            else{
                currentUser = User()
            }
            
            return currentUser;
        }
        return nil
    }
}
    
struct UserProprtiesKey {
    static let UserType = "UserType"
}


class User{
    
    private var me = PFUser.currentUser()!
    
    var name:String{
        get {return me.username!}
        set {me.username = newValue}
    }
    
//    var userType:UserType{
//        get{
//            return .Coach
//        }
//        set{
//            me[UserProprtiesKey.UserType] = newValue.rawValue
//        }
//    }
}

class Cocah: User {
    
    var userType:UserType{
        get{
            return .Coach
        }
        set{
            me[UserProprtiesKey.UserType] = UserType.Coach.rawValue
        }
    }
}

class Trainee: User {
    
    var userType:UserType{
        get{
            return .Trainee
        }
        set{
            me[UserProprtiesKey.UserType] = UserType.Trainee.rawValue
        }
    }
}


