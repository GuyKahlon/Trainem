//
//  Calendar.swift
//  Trainem
//
//  Created by idan haviv on 6/20/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKit

class Calendar: NSObject {//todo: move work to background threads
    
    //eventStore singleton for use accross the application
    static let eventStore = EKEventStore()
    var token =  dispatch_once_t()
    //keys: start date
    var cachedEvents = [NSDate : [EKEvent]]()
    static let defaultCalendar = NSCalendar.currentCalendar()
    
    override init()
    {
        super.init()
        
        dispatch_once(&token, { () -> Void in
            println("only once")
            self.requestCalendarPermissionFromUser()
        })
        
    }
    
    func requestCalendarPermissionFromUser()
    {
        Calendar.eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {(permissionGranted, error) -> Void in
     
            if (permissionGranted)
            {
                self.fetchCurrentMonthEvents()
            }
            else
            {
                assert(false, "must allow calendar")
                //todo: log & consider different handling
            }
        })
    }
    
    func fetchCurrentMonthEvents()
    {
        let date = NSDate()
        
        if let startOfMonthDate = date.startOfMonth(), endOfMonthDate = date.endOfMonth()
        {
            fetchEvents(fromDate: startOfMonthDate, toDate: endOfMonthDate)
        }
    }
    
    //todo: cache fetched events in a dictionary date->[events] for each calendar day
    func fetchEvents(# fromDate: NSDate, toDate: NSDate)->[EKEvent]?
    {
        var predicate = Calendar.eventStore.predicateForEventsWithStartDate(fromDate, endDate: toDate, calendars: nil)
        var events = Calendar.eventStore.eventsMatchingPredicate(predicate) //event array is not necessarily ordered
        if let fetchedEvents = events  as? [EKEvent]
        {
            cacheEvents(fetchedEvents)
            return fetchedEvents
        }
        
        return nil
    }
    
    func cacheEvents(events: [EKEvent])
    {
        let lockQueue = dispatch_queue_create("com.test.LockQueue", nil)
        dispatch_sync(lockQueue) {
            for event in events
            {
                if self.cachedEvents[event.startDate] == nil
                {
                    self.cachedEvents[event.startDate] = [EKEvent]()
                }
                
                var startDateCachedEvents = self.cachedEvents[event.startDate]
                startDateCachedEvents?.append(event)
            }
        }
    }
    
    //location is optional
    func saveEvent(# title: String, startDate: NSDate, endDate: NSDate, location: String? = nil)
    {
        var event = EKEvent(eventStore: Calendar.eventStore)
        event.calendar = Calendar.eventStore.defaultCalendarForNewEvents
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        
        var error: NSError?
        var eventSaved = Calendar.eventStore.saveEvent(event, span: EKSpanThisEvent, commit: true, error: &error)
    }
}

extension NSDate {
    
    func startOfMonth() -> NSDate?
    {
        let currentDateComponents = Calendar.defaultCalendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: self)
        let startOfMonth = Calendar.defaultCalendar.dateFromComponents(currentDateComponents)
//        var formatter = NSDateFormatter()
//        formatter.timeZone = NSTimeZone.systemTimeZone()
//        formatter.dateStyle = .ShortStyle
//        formatter.timeStyle = .ShortStyle
//        print(formatter.stringFromDate(startOfMonth!))
        return startOfMonth
    }
    
    func dateByAddingMonths(monthsToAdd: Int) -> NSDate? {
        
        let calendar = NSCalendar.currentCalendar()
        let months = NSDateComponents()
        months.month = monthsToAdd
        
        return calendar.dateByAddingComponents(months, toDate: self, options: nil)
    }
    
    func endOfMonth() -> NSDate? {
        
        let calendar = NSCalendar.currentCalendar()
        if let plusOneMonthDate = dateByAddingMonths(1) {
            let plusOneMonthDateComponents = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: plusOneMonthDate)
            
            let endOfMonth = calendar.dateFromComponents(plusOneMonthDateComponents)?.dateByAddingTimeInterval(-1)
            
            return endOfMonth
        }
        
        return nil
    }
}