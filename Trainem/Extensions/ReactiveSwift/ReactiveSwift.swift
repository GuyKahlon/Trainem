//
//  ReactiveSwift.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/17/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation

extension RACSignal {
    func subscribeNextAs<T>(nextClosure:(T) -> ()){
        self.subscribeNext {
            (next: AnyObject!) -> () in
            let nextAsT = next as! T
            nextClosure(nextAsT)
        }
    }
    
    func subscribeNextAs<T>(nextClosure:(T) -> (), errorClosure:(NSError)->()){
        self.subscribeNext({ (next:AnyObject!) -> Void in
            let nextAsT = next as! T
            nextClosure(nextAsT)
        }, error: { (error:NSError!) -> Void in
            errorClosure(error)
        })
    }
    
    func mapAs<T,U: AnyObject>(block: (T) -> U) -> Self {
        return map({(value: AnyObject!) in
            if let casted = value as? T {
                return block(casted)
            }
            return nil
        })
    }
    
    func filterAs<T>(block: (T) -> Bool) -> Self {
        return filter({(value: AnyObject!) in
            if let casted = value as? T {
                return block(casted)
            }
            return false
        })
    }
}
