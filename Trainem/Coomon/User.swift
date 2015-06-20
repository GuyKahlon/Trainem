//
//  User.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/19/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation

class User: PFUser{
    
    private var me = PFUser.currentUser()!
    
    var name:String{
        get{
            return me.username!
        }
        set{
            me.username = newValue
        }
    }
    
}