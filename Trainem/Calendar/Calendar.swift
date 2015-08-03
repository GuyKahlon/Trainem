//
//  Calendar.swift
//  Trainem
//
//  Created by idan haviv on 6/20/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKit

typealias SaveNewEventBlock = (savedEvent: EKEvent?, error: NSError?)->()
typealias RemoveEventBlock = (removedEvent: EKEvent?, error: NSError?)->()
typealias CacheNewEventsBlock = (newCachedEvents: Set<EKEvent>?, error: NSError?)->()
typealias UnCacheEventBlock = (unCachedEvent: EKEvent?, error: NSError?)->()
typealias FetchEventsBlock = (fetchedEvents: Set<EKEvent>?, error: NSError?)->()
typealias DateRangeEnumerationOperator = (fetchedEvents: Set<EKEvent>?, error: NSError?)->()

class Calendar: NSObject {//todo: move work to background threads
    
    let eventsCache = EventsCache()
    static var defaultCalendar = NSCalendar.currentCalendar()
    
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
    
    func fetchCurrentMonthEvents(completionBlock: FetchEventsBlock)
    {
        let date = NSDate()
        
        if let startOfMonthDate = date.startOfMonth(), endOfMonthDate = date.endOfMonth()
        {
            fetchEvents(fromDate: startOfMonthDate, toDate: endOfMonthDate, completionBlock: completionBlock)
        }
    }
    
    /* 
        :argument: date
        :return: Calendar events from the same day as date without consideration of time on day
    */
    func fetchEventsOnDay(date: NSDate, completionBlock: FetchEventsBlock)
    {
        fetchEvents(fromDate: date.dateWithBeginningOfDay(), toDate: date.dateWithEndOfDay(), completionBlock: completionBlock)
    }
    
    /*
        Fetches events for the default calendar and caches the events if not cached.
        All fetching methods should go through this method.
        Fetching is done in month unit batches
    */
    func fetchEvents(# fromDate: NSDate, toDate: NSDate, completionBlock: FetchEventsBlock)
    {
        if dateRangeIsCached(fromDate: fromDate, toDate: toDate)
        {
            let cachedEvents = self.cachedEvents(fromDate: fromDate, toDate: toDate)
            completionBlock(fetchedEvents: cachedEvents, error: nil)
        }
        
        let fetchAndCacheStartDate = fromDate.startOfMonth()
        let fetchAndCacheToDate = toDate.endOfMonth()
        var predicate = EventKitManager.eventStore.predicateForEventsWithStartDate(fetchAndCacheStartDate, endDate: fetchAndCacheToDate, calendars: nil)
        //todo: it's a synchronized method!
        var events = EventKitManager.eventStore.eventsMatchingPredicate(predicate) //event array is not necessarily ordered
        if let events = events as? [EKEvent]{
            cacheEvents(fromDate: fetchAndCacheStartDate!, toDate: fetchAndCacheToDate!, events: events, completionBlock: completionBlock)
        }
        cacheEvents(fromDate: fetchAndCacheStartDate!, toDate: fetchAndCacheToDate!, events: nil, completionBlock: completionBlock)
    }
    
    func cacheNewEvent(event: EKEvent, completionBlock: CacheNewEventsBlock? = nil)
    {
        cacheEvents(fromDate: event.startDate, toDate: event.startDate, events: [event], completionBlock: completionBlock)
    }
    
    func cacheEvents(# fromDate: NSDate, toDate: NSDate, events: [EKEvent]?, completionBlock: CacheNewEventsBlock? = nil)
    {
        eventsCache.cacheEvents(fromDate: fromDate, toDate: toDate, events: events, completionBlock: completionBlock)
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
            cacheNewEvent(event)
            
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
    
    func dateRangeIsCached(# fromDate: NSDate, toDate: NSDate)->Bool
    {
        return eventsCache.dateRangeIsCached(fromDate: fromDate, toDate: toDate);
    }
}