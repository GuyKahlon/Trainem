//
//  EventsCache.swift
//  Trainem
//
//  Created by idan haviv on 6/26/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKit

/*
    This class manages the events cache.
    It caches only consecutive days' events
*/
class EventsCache: NSObject {
   
    /*
        keys: start date without time on day
        cache entries can have several states for date x: 1. no entry x in cache iff event wasn't fetched from calendar
                                                             and so wasn't cached
                                                          2. object for key x is an empty events array iff events for date x
                                                             were fetched but no events on that day on calendar
                                                          3. object for key x is an array of events that should represent the
                                                             calendar state
    */
    static var cache = NSCache()
    let calendar = NSCalendar.currentCalendar()
    
    var serialCachingOperationQueue: NSOperationQueue
    var reteiveCacheOperationQueue: NSOperationQueue
    
    override init()
    {
        EventsCache.cache.name = "Events.Cache"
        serialCachingOperationQueue = NSOperationQueue()
        serialCachingOperationQueue.maxConcurrentOperationCount = 1 //serial queue
        serialCachingOperationQueue.name = "serialCachingOperationQueue"
        
        reteiveCacheOperationQueue = NSOperationQueue()
        reteiveCacheOperationQueue.name = "reteiveCacheOperationQueue"
        
        super.init()
    }
    
    /*
        serialized operation in a background thread
    */
    func cacheEvents(# fromDate: NSDate, toDate: NSDate, events: [EKEvent]?, completionBlock: CacheNewEventsBlock? = nil)
    {
        initCachedDateRange(fromDate: fromDate, toDate: toDate)
        
        if let events = events{
            //todo: code review - maybe refactor all this class to async methods
            //        serialCachingOperationQueue.addOperationWithBlock { () -> Void in
            let dateAndEventArray = events.map{ (var event: EKEvent) -> (NSDate, EKEvent) in
                let eventDate = event.startDate
                let eventDateWithoutTime = eventDate.dateWithOutTimeOfDay()
                return (eventDateWithoutTime, event)
            }
            
            for dateAndEvent in dateAndEventArray
            {
                let (date, event) = dateAndEvent
                if EventsCache.cache.objectForKey(date) == nil
                {
                    EventsCache.cache.setObject(Set<EKEvent>(), forKey: date)
                }
                
                if var events = EventsCache.cache.objectForKey(date) as? Set<EKEvent>
                {
                    events.insert(event)
                    EventsCache.cache.setObject(events, forKey: date)
                }
            }
            
            if let completionBlock = completionBlock
            {
                completionBlock(newCachedEvents: Set(events), error: nil)
            }
        }
    }
    
    //go over uninitalized date entries in cache and init them
    func initCachedDateRange(# fromDate: NSDate, toDate: NSDate)
    {
        let fromDateWithoutTime = fromDate.dateWithOutTimeOfDay()
        let previousDateWithoutTime = fromDateWithoutTime.previousDayWithSameTime()
        let toDate = toDate.dateWithOutTimeOfDay()
        
        var components = calendar.components(.CalendarUnitHour, fromDate: previousDateWithoutTime)
        
        calendar.enumerateDatesStartingAfterDate(previousDateWithoutTime, matchingComponents: components, options: .MatchStrictly, usingBlock: { (date: NSDate!, exactMatch: Bool, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            if date.isGreaterThanDate(toDate)
            {
                stop.memory = true
                return
            }
            
            if let cachedEventsForDate = EventsCache.cache.objectForKey(date) as? Set<EKEvent>
            {
                return
            }
            else
            {//initialize cache entry
                EventsCache.cache.setObject(Set<EKEvent>(), forKey: date)
            }
        })
    }
    
    //events are cached on day base, so the end date is redundent
    func unCacheEvent(event: EKEvent, completionBlock: UnCacheEventBlock? = nil)
    {
        var events = cachedEvents(fromDate: event.startDate, toDate: event.startDate)
        if count(events) > 0
        {
            events.remove(event)
            EventsCache.cache.setObject(events, forKey: event.startDate.dateWithOutTimeOfDay())
            if let completionBlock = completionBlock
            {
                completionBlock(unCachedEvent: event, error: nil)
            }
        }
        else if let completionBlock = completionBlock
        {
            let error = NSError(domain: "caching", code: 1, userInfo: ["failure" : "event not found in cache in the first place"])
            completionBlock(unCachedEvent: nil, error: nil)
        }
    }
    
    //cached events return events on the same day as required date
    func cachedEvents(# fromDate: NSDate, toDate: NSDate)->Set<EKEvent>
    {
        var cachedEvents = Set<EKEvent>()
        let fromDateWithoutTime = fromDate.dateWithOutTimeOfDay()
        let previousDateWithoutTime = fromDateWithoutTime.previousDayWithSameTime()
        let toDate = toDate.dateWithOutTimeOfDay()
     
        var components = calendar.components(.CalendarUnitHour, fromDate: previousDateWithoutTime)
        
        calendar.enumerateDatesStartingAfterDate(previousDateWithoutTime, matchingComponents: components, options: .MatchStrictly, usingBlock: { (date: NSDate!, exactMatch: Bool, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            if date.isGreaterThanDate(toDate)
            {
                stop.memory = true
                return
            }
            
            if let cachedEventsForDate = EventsCache.cache.objectForKey(date) as? Set<EKEvent>
            {
                cachedEvents = cachedEvents.union(cachedEventsForDate)
            }
        })
        
        return cachedEvents
    }
    
    func dateRangeIsCached(# fromDate: NSDate, toDate: NSDate)->Bool
    {
        if fromDate == toDate
        {
            return dateIsCached(fromDate)
        }
        
        let fromDateWithoutTime = fromDate.dateWithOutTimeOfDay()
        let previousDateWithoutTime = fromDateWithoutTime.previousDayWithSameTime()
        let toDate = toDate.dateWithOutTimeOfDay()
        
        var dateRangeIsCached = true
        
        var components = calendar.components(.CalendarUnitHour, fromDate: previousDateWithoutTime)
        
        calendar.enumerateDatesStartingAfterDate(previousDateWithoutTime, matchingComponents: components, options: .MatchStrictly, usingBlock: { (date: NSDate!, exactMatch: Bool, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            if date.isGreaterThanDate(toDate)
            {
                stop.memory = true
                return
            }
            
            let dayIsCached = self.dateIsCached(date)
            
            if !dayIsCached
            {
                dateRangeIsCached = false
                stop.memory = true
                return
            }
        })
        
        return dateRangeIsCached
    }
    
    // a date is cached iff its entry in the cache is not nil; e.g. if object for key date in cache is an emptry array it is cached but there are no events on that day
    func dateIsCached(date: NSDate) -> Bool
    {
        if let cachedEventsForDate = EventsCache.cache.objectForKey(date) as? Set<EKEvent>
        {
            return true
        }
        
        return false
    }
    
    func cleanEventsCache()
    {
        EventsCache.cache.removeAllObjects()
    }
}
