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
    
    let eventsCache = EventsCache()
    static let defaultCalendar = NSCalendar.currentCalendar()
    
    func requestCalendarPermissionFromUserAndFetchEvents()
    {
        EventKitManager.eventStore.requestAccessToEntityType(EKEntityTypeEvent, completion: {(permissionGranted, error) -> Void in
     
            if (permissionGranted)
            {
                //todo: maybe return method call
//                self.fetchCurrentMonthEvents()
            }
            else
            {
                assert(false, "must allow calendar")
                //todo: log & consider different handling
            }
        })
    }
    
    func fetchCurrentMonthEvents()->Set<EKEvent>?
    {
        let date = NSDate()
        
        if let startOfMonthDate = date.startOfMonth(), endOfMonthDate = date.endOfMonth()
        {
            return fetchEvents(fromDate: startOfMonthDate, toDate: endOfMonthDate)
        }
        
        //todo: why can't it return nil?
        return Set<EKEvent>()
    }
    
    /* 
        :argument: date
        :return: Calendar events from the same day as date without consideration of time on day
    */
    func fetchEventsOnDay(date: NSDate)->Set<EKEvent>?
    {
        let dailyEvents = fetchEvents(fromDate: date.dateWithBeginningOfDay(), toDate: date.dateWithEndOfDay())
        return dailyEvents
    }
    
    /*
        Fetches events for the default calendar and caches the events if not cached.
        All fetching methods should go through this method.
        Fetching is done in month unit batches
    */
    func fetchEvents(# fromDate: NSDate, toDate: NSDate)->Set<EKEvent>?
    {
        println("from date: \(fromDate) to date: \(toDate)")
        
        if eventsCache.dateRangeIsCached(fromDate: fromDate, toDate: toDate)
        {
            return eventsCache.cachedEvents(fromDate: fromDate, toDate: toDate)
        }
        
        let fetchAndCacheStartDate = fromDate.startOfMonth()
        let fetchAndCacheToDate = toDate.endOfMonth()
        var predicate = EventKitManager.eventStore.predicateForEventsWithStartDate(fetchAndCacheStartDate, endDate: fetchAndCacheToDate, calendars: nil)
        //todo: it's a synchronized method!
        var events = EventKitManager.eventStore.eventsMatchingPredicate(predicate) //event array is not necessarily ordered
        
        if let fetchedEvents = events  as? [EKEvent]
        {
            //todo: consider replacing forced unwrapping
            cacheEvents(fromDate: fetchAndCacheStartDate!, toDate: fetchAndCacheToDate!, events: fetchedEvents)
            return eventsCache.cachedEvents(fromDate: fromDate, toDate: toDate)
        }
        
        eventsCache.updateFirstAndLastCachedDates(startDate: fetchAndCacheStartDate!, endDate: fetchAndCacheToDate!)
        return nil
    }
    
    func cacheEvents(# fromDate: NSDate, toDate: NSDate, events: [EKEvent])
    {
        eventsCache.cacheEvents(fromDate: fromDate, toDate: toDate, events: events)
    }
    
    //todo: add function to updateCacheForNewEvent - we cache a dictionary for daily events and wouldn't want to update the cache for future fetches for the same day, and a new event is the exception
    
    //todo: maybe release cache in dealloc?
    
    //location is optional
    func saveEvent(# title: String, startDate: NSDate, endDate: NSDate, location: String? = nil)
    {
        var event = EKEvent(eventStore: EventKitManager.eventStore)
        event.calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        
        var error: NSError?
        var eventSaved = EventKitManager.eventStore.saveEvent(event, span: EKSpanThisEvent, commit: true, error: &error)
    }
}

extension NSDate {
    
    func startOfMonth() -> NSDate?
    {
        let currentDateComponents = Calendar.defaultCalendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: self)
        let startOfMonth = Calendar.defaultCalendar.dateFromComponents(currentDateComponents)
        return startOfMonth
    }
    
    func isDateOnTheSameDay(otherDate: NSDate)->Bool
    {
        return NSCalendar.currentCalendar().isDate(self, inSameDayAsDate: otherDate)
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
    
    func isGreaterThanDate(dateToCompare : NSDate) -> Bool
    {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
    }
    
    
    func isLessThanDate(dateToCompare : NSDate) -> Bool
    {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
    }
}