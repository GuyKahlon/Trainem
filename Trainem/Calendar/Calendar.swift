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
    static var defaultCalendar = NSCalendar.currentCalendar()
    typealias SaveNewEventBlock = (savedEvent: EKEvent?, error: NSError?)->()
    typealias RemoveEventBlock = (removedEvent: EKEvent?, error: NSError?)->()
    typealias CacheNewEventsBlock = (newCachedEvents: [EKEvent]?, error: NSError?)->()
    typealias UnCacheEventBlock = (unCachedEvent: EKEvent?, error: NSError?)->()
    
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
        
        return nil
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
        if eventsCache.dateRangeIsCached(fromDate: fromDate, toDate: toDate)
        {
            return eventsCache.cachedEvents(fromDate: fromDate, toDate: toDate)
        }
        
        let fetchAndCacheStartDate = fromDate.startOfMonth()
        let fetchAndCacheToDate = toDate.endOfMonth()
        var predicate = EventKitManager.eventStore.predicateForEventsWithStartDate(fetchAndCacheStartDate, endDate: fetchAndCacheToDate, calendars: nil)
        //todo: it's a synchronized method!
        var events = EventKitManager.eventStore.eventsMatchingPredicate(predicate) //event array is not necessarily ordered
        
        if let fetchedEvents = events  as? [EKEvent] where fetchedEvents.count > 0
        {
            //todo: consider replacing forced unwrapping
            cacheEvents(fromDate: fetchAndCacheStartDate!, toDate: fetchAndCacheToDate!, events: fetchedEvents)
            return eventsCache.cachedEvents(fromDate: fromDate, toDate: toDate)
        }
        
        //required in case there are no events on those dates. we still want to update the cache range to prevent unneeded work
        eventsCache.updateFirstAndLastCachedDates(startDate: fetchAndCacheStartDate!, endDate: fetchAndCacheToDate!)
        return nil
    }
    
    func cacheNewEvent(event: EKEvent, completionBlock: CacheNewEventsBlock?)
    {
        eventsCache.cacheNewEvent(event, completionBlock: completionBlock)
    }
    
    func cacheEvents(# fromDate: NSDate, toDate: NSDate, events: [EKEvent])
    {
        eventsCache.cacheEvents(fromDate: fromDate, toDate: toDate, events: events)
    }
    
    func cachedEvents(# fromDate: NSDate, toDate: NSDate)->Set<EKEvent>
    {
        return eventsCache.cachedEvents(fromDate: fromDate, toDate: toDate)
    }
    
    //todo: maybe release cache in dealloc?
    
    //location is optional
    func saveEventToCalendar(# title: String, startDate: NSDate, endDate: NSDate, location: String? = nil, completionBlock: SaveNewEventBlock? = nil)
    {
        var event = EKEvent(eventStore: EventKitManager.eventStore)
        event.calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        
        var error: NSError?
        var eventSaved = EventKitManager.eventStore.saveEvent(event, span: EKSpanThisEvent, commit: true, error: &error)
        
        if eventSaved
        {
            self.eventsCache.cacheNewEvent(event)
            
            if let completionBlock = completionBlock
            {
                completionBlock(savedEvent: event, error: nil)
            }
        }
        else
        {
            if let completionBlock = completionBlock
            {
                let error = NSError(domain: "calendar", code: 1, userInfo: ["failure" : "event not saved in event store"])
                completionBlock(savedEvent: nil, error: error)
            }
            NSLog("error creating new event: \(error)")
        }
    }
    
    func removeEventFromCalendar(event: EKEvent, completionBlock: RemoveEventBlock? = nil)
    {
        var error: NSError?
        var eventRemoved = EventKitManager.eventStore.removeEvent(event, span: EKSpanThisEvent, commit: true, error: &error)
        
        if eventRemoved
        {
            unCacheEvent(event)
            
            if let completionBlock = completionBlock
            {
                completionBlock(removedEvent: event, error: nil)
            }
        }
        else
        {
            if let completionBlock = completionBlock
            {
                let error = NSError(domain: "calendar", code: 1, userInfo: ["failure" : "event not removed from event store"])
                completionBlock(removedEvent: nil, error: error)
            }
            NSLog("error creating new event: \(error)")
        }
    }
    
    func unCacheEvent(event:EKEvent, completionBlock: UnCacheEventBlock? = nil)
    {
        eventsCache.unCacheEvent(event, completionBlock: completionBlock)
    }
    
    func cleanEventsCache()
    {
        eventsCache.cleanEventsCache()
    }
}