//
//  ServerUtilities.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/19/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation

typealias Parseresponse = (user: PFUser?, error: NSError?)

//let kParseErrorInvalidEmail             = 125

struct ParseErrorsCode {
    static let LoginInvalidCardentials    = 101
    static let RegisterUserAlreadyExist   = 202
    static let InvalidEmail               = 125
}

class ParseUtilities{

    class func login(#userName: String, password:String)->RACSignal{
       return RACSignal.createSignal({ subscriber in
            PFUser.logInWithUsernameInBackground(userName, password: password) { user, error in
                if error == nil{
                    subscriber.sendNext(user!)
                    subscriber.sendCompleted()
                }
                else{
                    subscriber.sendNext(error)
                }
            }
            return nil
       })
    }
    
    class func signUp(#userName: String, password:String)->RACSignal{
        return RACSignal.createSignal({ subscriber in
            var user = PFUser()
            user.username  = userName
            user.password  = password
            user.email     = userName
            
            user.signUpInBackgroundWithBlock({ (succeeded:Bool, error: NSError?) -> Void in
                if succeeded == true{
                    subscriber.sendNext(true)
                    subscriber.sendCompleted()
                }
                else{
                    subscriber.sendNext(error)
                }
            })
            return nil
        })
    }
    
}