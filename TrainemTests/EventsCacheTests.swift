//
//  EventsCacheTests.swift
//  Trainem
//
//  Created by idan haviv on 7/10/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import XCTest
import EventKit

class EventsTests: XCTestCase {

    var eventsCache = EventsCache()
    var calendarModel = Calendar()
    var calendar: EKCalendar?
    
    override func setUp() {
        super.setUp()
        calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        calendarModel.cleanEventsCache()
    }
    
    override func tearDown() {
        calendarModel.cleanEventsCache()
        calendar = nil
        super.tearDown()
    }

    //todo: code review - problem with asynchronous method returns
    func testUnCacheEvent() {
        
        let expectation = expectationWithDescription("all methods are done")
        
        var event = EKEvent(eventStore: EventKitManager.eventStore)
        event.calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        event.title = "new event"
        event.startDate = NSDate()
        event.endDate = NSDate()
        
        var cachedEvents: Set<EKEvent>?
        
        self.eventsCache.cacheNewEvent(event, completionBlock: { (newCachedEvents, error) -> () in
            
            if let error = error
            {
                XCTFail("event not cached: \(error)")
                return
            }
            
            cachedEvents = self.eventsCache.cachedEvents(fromDate: NSDate(), toDate: NSDate())
            
            if !(cachedEvents!.count > 0)
            {
                XCTFail("event not cached: \(error)")
            }
        
            self.eventsCache.unCacheEvent(event, completionBlock: { (unCachedEvent, error) -> () in
                
                if let error = error
                {
                    XCTFail("event not uncached: \(error)")
                    return
                }
                
                cachedEvents = self.eventsCache.cachedEvents(fromDate: NSDate(), toDate: NSDate())
                if (cachedEvents!.count > 0)
                {
                    XCTFail("event \(event) not un-cached properly")
                }
                
                expectation.fulfill()
            })
        })
    }
    
    /*
        tests saving and caching a new event to calendar and then removal from calendar and uncaching
        uses dispatch_sync for keeping the order of method calls
    */
    func testCreateAndRemoveEvent() {
        
        let initialCachedEvents = calendarModel.eventsCache.cachedEvents(fromDate: NSDate(), toDate: NSDate())
        XCTAssert(initialCachedEvents.count == 0, "events cache is not clean as a preliminary for this test")
        
        let expectation = expectationWithDescription("all methods are done")
        
        var event = EKEvent(eventStore: EventKitManager.eventStore)
        event.calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        event.title = "new event"
        event.startDate = NSDate()
        event.endDate = NSDate()
        
        self.calendarModel.saveEventToCalendar(title: event.title, startDate: event.startDate, endDate: event.endDate, location: nil, completionBlock: { (savedEvent, error) -> () in
            
            if let error = error
            {
                XCTFail("event not saved: \(error)")
                return
            }
            
            if let currentEvents = self.calendarModel.fetchEventsOnDay(event.startDate), currentEvent = currentEvents.first
            {
                XCTAssert(currentEvent.title == event.title && currentEvent.startDate == event.startDate && currentEvent.endDate == event.endDate, "saved event's properties not as expected")
            }
            else
            {
                XCTFail("event not saved")
            }
            
            self.calendarModel.eventsCache.cacheNewEvent(event, completionBlock: { (newCachedEvents, error) -> () in
                if let error = error
                {
                    XCTFail("event not cached: \(error)")
                    return
                }
                
                let cachedEvents = self.calendarModel.eventsCache.cachedEvents(fromDate: event.startDate, toDate: event.endDate)
                XCTAssert(cachedEvents.count == 1, "event not cached")
                
                self.calendarModel.removeEventFromCalendar(event, completionBlock: { (removedEvent, error) -> () in
                    if let error = error
                    {
                        XCTFail("event not removed from calendar: \(error)")
                        return
                    }
                    
                    let currentEventsAfterRemoval = self.calendarModel.fetchEventsOnDay(event.startDate)
                    XCTAssert(currentEventsAfterRemoval!.count == 0, "event not removed from calendar")
                    
                    let cachedEventsAfterRemoval = self.calendarModel.eventsCache.cachedEvents(fromDate: event.startDate, toDate: event.endDate)
                    XCTAssert(cachedEventsAfterRemoval.count == 0, "event not uncached")
                    
                    expectation.fulfill()
                })
            })
        })
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
