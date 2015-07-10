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

class EventsCacheTests: XCTestCase {

    var eventsCache = EventsCache()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testUnCacheEvent() {
        var event = EKEvent(eventStore: EventKitManager.eventStore)
        event.calendar = EventKitManager.eventStore.defaultCalendarForNewEvents
        event.title = "new event"
        event.startDate = NSDate()
        event.endDate = NSDate()
        
        var cachedEvents: Set<EKEvent>?
        
        eventsCache.cacheNewEvent(event)
        dispatch_sync(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), {
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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }

}
