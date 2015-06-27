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
    It contains only consecutive days' events
*/
class EventsCache: NSObject {
   
    //keys: start date without time
    var cachedEventsDictionary = [NSDate : Set<EKEvent>]()
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
                if self.cachedEventsDictionary[date] == nil
                {
                    self.cachedEventsDictionary[date] = Set<EKEvent>()
                }
                
                self.cachedEventsDictionary[date]?.insert(event)
                
                self.updateFirstAndLastCachedDates(startDate: fromDate, endDate: toDate)
            }
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
        
        if startDate.isLessThanDate(firstCachedDate!) && !endDate.isLessThanDate(firstCachedDate!)
        {
            firstCachedDate = startDate
        }
        
        if endDate.isGreaterThanDate(lastCachedDate!) && !startDate.isGreaterThanDate(lastCachedDate!)
        {
            lastCachedDate = endDate
        }
    }
    
    func updateFirstCachedDate(var date: NSDate)
    {
        date = date.dateWithOutTimeOfDay()
        
        if let first = firstCachedDate
        {
            if date.isLessThanDate(first)
            {
                firstCachedDate = date
            }
            
            return
        }
        else
        {
            firstCachedDate = date
        }
    }
    
    func updateLastCachedDate(var date: NSDate)
    {
        date = date.dateWithOutTimeOfDay()
        
        if let last = lastCachedDate
        {
            if date.isGreaterThanDate(last)
            {
                lastCachedDate = date
            }
            
            return
        }
        else
        {
            lastCachedDate = date
        }
    }
    
    func cachedEvents(# fromDate: NSDate, toDate: NSDate)->Set<EKEvent>
    {
        var events = Set<EKEvent>()
        
        for date in cachedEventsDictionary.keys
        {
            if !date.isGreaterThanDate(toDate) && !date.isLessThanDate(fromDate)
            {
                events = events.union(cachedEventsDictionary[date]!)
            }
        }
        
        return events
    }
    
    func cachedEvents()->Set<EKEvent>
    {
        var events = Set<EKEvent>()
        for eventArray in cachedEventsDictionary.values
        {
            events = events.union(eventArray)
        }
        
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
