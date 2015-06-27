//
//  EventKitManager.swift
//  Trainem
//
//  Created by idan haviv on 6/27/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKit

class EventKitManager: NSObject {
   
    //eventStore singleton for use accross the application
    static let eventStore = EKEventStore()
}
