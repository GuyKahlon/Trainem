//
//  Calendar.swift
//  Trainem
//
//  Created by idan haviv on 6/20/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKit

protocol CalenderModelDelegate: class{
    func eventsDidUpdate()
}

class Calendar: NSObject {//todo: move work to background threads
    
    weak var delegate: CalenderModelDelegate?
    //eventStore singleton for use accross the application
    static let eventStore = EKEventStore()
    var token =  dispatch_once_t()
    //keys: start date without time
    var cachedEvents = [NSDate : [EKEvent]]()
    static let defaultCalendar = NSCalendar.currentCalendar()
    
    func requestCalendarPermissionFromUserAndFetchEvents()
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
    
    /* 
        :argument: date
        :return: Calendar events from the same day as date without consideration of time on day
    */
    func fetchEventsOnDay(date: NSDate)->[EKEvent]?
    {
        let dailyEvents = fetchEvents(fromDate: date.dateWithBeginningOfDay(), toDate: date.dateWithEndOfDay())
        return dailyEvents
    }
    
    /*
        Fetches events for the default calendar and caches the events if not cached.
        All fetching methods should go through this method.
    */
    func fetchEvents(# fromDate: NSDate, toDate: NSDate)->[EKEvent]?
    {
//        if dateRangeIsContainedInCache()
//        {
//            
//        }
        
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
        //todo: consider different way to lock
        let lockQueue = dispatch_queue_create("com.test.LockQueue", nil)
        dispatch_sync(lockQueue) {
            
            let dateAndEventArray = events.map{ (var event: EKEvent) -> (NSDate, EKEvent) in
                let eventDate = event.startDate
                let eventDateWithoutTime = eventDate.dateWithOutTimeOfDay()
                return (eventDateWithoutTime, event)
            }
            
            for dateAndEvent in dateAndEventArray
            {
                let (date, event) = dateAndEvent
                if self.cachedEvents[date] == nil
                {
                    self.cachedEvents[date] = [EKEvent]()
                }
                
                self.cachedEvents[date]?.append(event)
            }
            
            self.delegate?.eventsDidUpdate()
        }
    }
    
    //todo: add function to updateCacheForNewEvent - we cache a dictionary for daily events and wouldn't want to update the cache for future fetches for the same day, and a new event is the exception
    
    //todo: maybe release cache in dealloc?
    
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
    
    func dateWithOutTimeOfDay()->(NSDate)
    {
        let components = NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: self)
        let newDate = NSCalendar.currentCalendar().dateFromComponents(components)
        return newDate!
    }
    
    func dateWithBeginningOfDay()->NSDate
    {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: self)
        return calendar.dateFromComponents(components)!
    }
    
    func dateWithEndOfDay()->NSDate
    {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = 1
        
        var newDate = calendar.dateByAddingComponents(components, toDate: self.dateWithBeginningOfDay(), options: nil)
        newDate = newDate?.dateByAddingTimeInterval(-1)
        return newDate!
    }
}