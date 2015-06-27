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
    let cache = NSCache()
    let calendar = NSCalendar.currentCalendar()
    var firstCachedDate: NSDate?
    var lastCachedDate: NSDate?
    
    func cacheEvents(# fromDate: NSDate, toDate: NSDate, events: [EKEvent])
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
                if self.cache.objectForKey(date) == nil
                {
                    self.cache.setObject(Set<EKEvent>(), forKey: date)
                }
                
                if var events = self.cache.objectForKey(date) as? Set<EKEvent>
                {
                    events.insert(event)
                    self.cache.setObject(events, forKey: date)
                }
                
                self.updateFirstAndLastCachedDates(startDate: fromDate, endDate: toDate)
            }
        }
    }
    
    //update the cached range if and only if the new range is overlapping or containing current cached date range
    func updateFirstAndLastCachedDates(# startDate: NSDate, endDate: NSDate)
    {
        //todo: add NSCacheDelegate to control the firstCachedDate and last in case something is removed from cache
        if firstCachedDate == nil
        {
            firstCachedDate = startDate
        }
        
        if lastCachedDate == nil
        {
            lastCachedDate = endDate
        }
        //the 2 hour comparison is for 2 reasons: day light savings causes a 1 hour gap, endDate is on 23:59 and start date is on 00:00
        if startDate.isLessThanDate(firstCachedDate!) && !endDate.isLessThanDateByMoreThanTwoHours(firstCachedDate!)
        {
            firstCachedDate = startDate
        }
        
        if endDate.isGreaterThanDate(lastCachedDate!) && !startDate.isGreaterThanDateByMoreThanTwoHours(lastCachedDate!)
        {
            lastCachedDate = endDate
        }
    }
    
    func cachedEvents(# fromDate: NSDate, toDate: NSDate)->Set<EKEvent>
    {
        let toDate = toDate.dateWithOutTimeOfDay()
        var events = Set<EKEvent>()
        let fromDateWithoutTime = fromDate.dateWithOutTimeOfDay()
        let previousDateWithoutTime = fromDate.previousDayWithSameTime()
     
        var components = calendar.components(.CalendarUnitHour, fromDate: previousDateWithoutTime)

        var dateCount = 0
        calendar.enumerateDatesStartingAfterDate(previousDateWithoutTime, matchingComponents: components, options: .MatchStrictly, usingBlock: { (date: NSDate!, exactMatch: Bool, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            
            if date.isGreaterThanDate(toDate)
            {
                stop.memory = true
            }
            
//            println("\(self.cache.objectForKey(date))")
            if let cachedEventsForDate = self.cache.objectForKey(date) as? Set<EKEvent>
            {
                println(cachedEventsForDate.first)
                events = events.union(cachedEventsForDate)
            }
        })
        
        return events
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
}
