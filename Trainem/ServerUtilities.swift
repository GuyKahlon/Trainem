//
//  ServerUtilities.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/19/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation

protocol TrainemBaseClientProtocol{
    
    func login(userName userName: String, password:String)->RACSignal
    func signUp(userName userName: String, password:String)->RACSignal
}


/*
    We use here with Factory Method design pattern to replace class constructors, abstracthing the process of object generation so that the type of the object instantiated can be determined at run time.
    The Client Factory method return the Client protocol to support deppendency Injection.
*/
class TrainemClientFactory {
    
    class func TrainemClientForEnvironment(runTimeProvider:RunTimeProvider) -> TrainemBaseClientProtocol {
        
        switch runTimeProvider.user {
            case .Trainee:
                return TrainemTraineeClient.sharedInstance
            case .Coach:
                return TrainemCoachClient.sharedInstance
        }
    }
}

typealias Parseresponse = (user: PFUser?, error: NSError?)

struct ParseErrorsCode {
    static let LoginInvalidCardentials    = 101
    static let RegisterUserAlreadyExist   = 202
    static let InvalidEmail               = 125
}

class TrainemBaseClient: TrainemBaseClientProtocol{
    
    func login(userName userName: String, password:String)->RACSignal{
        return RACSignal.createSignal({ subscriber in
            PFUser.logInWithUsernameInBackground(userName, password: password) { user, error in
                if error == nil{
                    subscriber.sendNext(UserFactory.getCurrentUser())
                    subscriber.sendCompleted()
                }
                else{
                    subscriber.sendError(error)
                }
            }
            return nil
        }).replayLazily()
    }
    
    func signUp(userName userName: String, password:String)->RACSignal{
        return RACSignal.createSignal({ subscriber in
            let user = PFUser()
            user.username  = userName
            user.password  = password
            user.email     = userName
            user.signUpInBackgroundWithBlock({ (succeeded:Bool, error: NSError?) -> Void in
                if succeeded == true{
                    subscriber.sendNext(true)
                    subscriber.sendCompleted()
                }
                else{
                    subscriber.sendError(error)
                }
            })
            return nil
        }).replayLazily()
    }
}

/*
    We use here with the Singelton design pattern to ensures we have only on object of particular Client (User or Coach), All further references to Client refer to the same underlying instance.
*/
class TrainemTraineeClient:TrainemBaseClient{
    
    static let sharedInstance = TrainemTraineeClient()
    private override init() {}
    
    override func signUp(userName userName: String, password:String)->RACSignal{
        
        let signUpSignal = super.signUp(userName: userName, password: password)
        
        signUpSignal.filter { (signUpResponse:AnyObject!) -> Bool in
            if let response = signUpResponse as? Bool{
                return response
            }
            return false
        }.subscribeNext { response in
            if let user = PFUser.currentUser(){
                user[UserProprtiesKey.UserType] = UserType.Trainee.rawValue
                user.saveEventually(nil)
            }
        }
        return signUpSignal
    }
}

class TrainemCoachClient: TrainemBaseClient{
    
    static let sharedInstance = TrainemCoachClient()
    private override init() {}
    
    override func signUp(userName userName: String, password:String)->RACSignal{
        
        let signUpSignal = super.signUp(userName: userName, password: password)
        
        signUpSignal.filter { (signUpResponse:AnyObject!) -> Bool in
            if let response = signUpResponse as? Bool{
                return response
            }
            return false
            }.subscribeNext { response in
                if let user = PFUser.currentUser(){
                    user[UserProprtiesKey.UserType] = UserType.Coach.rawValue
                    user.saveEventually(nil)
            }
        }
        return signUpSignal
    }
}




