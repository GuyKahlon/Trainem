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
   
    //keys: start date without time on day
    static var cache = NSCache()
    let calendar = NSCalendar.currentCalendar()
    var firstCachedDate: NSDate?
    var lastCachedDate: NSDate?
    
    var serialCachingOperationQueue: NSOperationQueue
    var reteiveCacheOperationQueue: NSOperationQueue
    
    typealias CacheNewEventsBlock = (newCachedEvents: [EKEvent]?, error: NSError?)->()
    typealias UnCacheEventBlock = (unCachedEvent: EKEvent?, error: NSError?)->()
    
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
    
    //events are cached on day base, so the end date is redundent
    //completion block is used mainly for testing
    func cacheNewEvent(event: EKEvent, completionBlock: CacheNewEventsBlock? = nil)
    {
        cacheEvents(fromDate: event.startDate, toDate: event.startDate, events: [event], completionBlock: completionBlock)
    }
    
    /*
        serialized operation in a background thread
    */
    func cacheEvents(# fromDate: NSDate, toDate: NSDate, events: [EKEvent], completionBlock: CacheNewEventsBlock? = nil)
    {
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
            
            self.updateFirstAndLastCachedDates(startDate: fromDate, endDate: toDate)
        }
        
        if let completionBlock = completionBlock
        {
            completionBlock(newCachedEvents: events, error: nil)
        }
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
    
    //update the cached range if and only if the new range is overlapping or containing current cached date range
    func updateFirstAndLastCachedDates(# startDate: NSDate, endDate: NSDate)
    {
        if firstCachedDate == nil
        {
            firstCachedDate = startDate
        }
        
        if lastCachedDate == nil
        {
            lastCachedDate = endDate
        }
        //the 2 hour comparison is for 2 reasons: day light savings causes a 1 hour gap, endDate is on 23:59 and start date is on 00:00
        if startDate.isLessThanDate(firstCachedDate!) && !endDate.isLessThanDate(firstCachedDate!)
        {
            firstCachedDate = startDate
        }
        
        if endDate.isGreaterThanDate(lastCachedDate!) && !startDate.isGreaterThanDate(lastCachedDate!)
        {
            lastCachedDate = endDate
        }
    }
    
    
    func cachedEvents(# fromDate: NSDate, toDate: NSDate)->Set<EKEvent>
    {
        let toDate = toDate.dateWithOutTimeOfDay()
        var cachedEvents = Set<EKEvent>()
        let fromDateWithoutTime = fromDate.dateWithOutTimeOfDay()
        let previousDateWithoutTime = fromDateWithoutTime.previousDayWithSameTime()
     
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
        let fromDay = fromDate.dateWithOutTimeOfDay()
        let toDay = toDate.dateWithOutTimeOfDay()
        
        if let first = firstCachedDate, last = lastCachedDate
        {
            return !last.isLessThanDate(fromDate) && !first.isGreaterThanDate(toDate)
        }
        
        return false
    }
    
    func cleanEventsCache()
    {
        EventsCache.cache.removeAllObjects()
//        EventsCache.cache = NSCache()
    }
}
