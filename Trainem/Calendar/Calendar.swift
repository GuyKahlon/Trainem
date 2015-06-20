//
//  Calendar.swift
//  Trainem
//
//  Created by idan haviv on 6/20/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKit

class Calendar: NSObject {
    
    //event store singleton for use accross the application
    static let eventStore = EKEventStore()
    
    override init()
    {
        super.init()
        
        requestCalendarPermissionFromUser()
    }
    
    func requestCalendarPermissionFromUser()
    {
        Calendar.eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {(permissionGranted, error) -> Void in
     
            if (permissionGranted)
            {
                //todo: log
            }
            else
            {
                assert(false, "must allow calendar")
                //todo: log & consider different handling
            }
        })
    }
    
    //location is optional
    func newEvent(# title: String, startDate: NSDate, endDate: NSDate, location: String? = nil)
    {
        var event = EKEvent(eventStore: Calendar.eventStore)
        event.calendar = Calendar.eventStore.defaultCalendarForNewEvents
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        
        var error: NSError?
        var eventSaved = Calendar.eventStore.saveEvent(event, span: EKSpanThisEvent, commit: true, error: &error)
    }
    
    func fetchEvents(# fromDate: NSDate, toDate: NSDate)->NSArray?
    {
        var predicate = Calendar.eventStore.predicateForEventsWithStartDate(fromDate, endDate: toDate, calendars: nil)
        var events = Calendar.eventStore.eventsMatchingPredicate(predicate)
        
        return events
    }
}