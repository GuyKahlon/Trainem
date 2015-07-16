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
    var calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    //todo: code review - problem with asynchronous method returns
    func testUnCacheEvent() {
        var event = EKEvent(eventStore: EventKitManager.eventStore)
        event.calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        event.title = "new event"
        event.startDate = NSDate()
        event.endDate = NSDate()
        
        var cachedEvents: Set<EKEvent>?
        
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), {
            self.eventsCache.cacheNewEvent(event)
            cachedEvents = self.eventsCache.cachedEvents(fromDate: NSDate(), toDate: NSDate())
        })
        
        if !(cachedEvents!.count > 0)
        {
            XCTAssert(false, "event \(event) not cached properly")
        }
        
        eventsCache.unCacheEvent(event)
        
        cachedEvents = eventsCache.cachedEvents(fromDate: NSDate(), toDate: NSDate())
        if (cachedEvents!.count > 0)
        {
            XCTAssert(false, "event \(event) not un-cached properly")
        }
    }
    
    /*
        tests saving and caching a new event to calendar and then removal from calendar and uncaching
        uses dispatch_sync for keeping the order of method calls
    */
    func testCreateAndRemoveEvent() {
        
        calendarModel.cleanEventsCache()
        
        let initialCachedEvents = calendarModel.eventsCache.cachedEvents(fromDate: NSDate(), toDate: NSDate())
        XCTAssert(initialCachedEvents.count == 0, "events cache is not clean as a preliminary for this test")
        
        var event = EKEvent(eventStore: EventKitManager.eventStore)
        event.calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        event.title = "new event"
        event.startDate = NSDate()
        event.endDate = NSDate()
        
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), { () -> Void in
            self.calendarModel.saveEventToCalendar(title: event.title, startDate: event.startDate, endDate: event.endDate)
        })
        
        let currentEvents = self.calendarModel.fetchEventsOnDay(event.startDate)
        XCTAssert(currentEvents!.count == 1, "event not saved as expected")
        
        if let currentEvents = currentEvents, currentEvent = currentEvents.first
        {
            XCTAssert(currentEvent.title == event.title && currentEvent.startDate == event.startDate && currentEvent.endDate == event.endDate, "saved event's properties not as expected")
        }
        else
        {
            XCTAssert(false, "event not saved")
        }
        
        let cachedEvents = calendarModel.eventsCache.cachedEvents(fromDate: event.startDate, toDate: event.endDate)
        XCTAssert(cachedEvents.count == 1, "event not cached")
        
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), { () -> Void in
            self.calendarModel.removeEventFromCalendar(event)
        })
        
        let currentEventsAfterRemoval = self.calendarModel.fetchEventsOnDay(event.startDate)
        XCTAssert(currentEventsAfterRemoval!.count == 0, "event not removed from calendar")
        
        let cachedEventsAfterRemoval = calendarModel.eventsCache.cachedEvents(fromDate: event.startDate, toDate: event.endDate)
        XCTAssert(cachedEventsAfterRemoval.count == 0, "event not uncached")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
