//
//  GoogleCalendarModelAdapter.swift
//  Trainem
//
//  Created by idan haviv on 7/16/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation
import EventKit

/* 
    this is a GoogleCalendarModel adapter to be used by a table view controller
    the model is a dictionary with NSDate as keys that represent a whole month. that date would be
    the startOfMonth() NSDate extension return value. eventsModel values are sorted EKEvents arrays
*/
class GoogleCalendarModelAdaptor {
    
    private let model: Calendar
    
    //events model keys are NSDate that represent a month, and values are all events on that month
    private var eventsModel = [NSDate : [EKEvent]]()
    
    init(model: Calendar)
    {
        self.model = model
        eventsModel = constructModel()
    }
    
    private func constructModel() -> [NSDate : [EKEvent]]
    {
        if let events = monthlyEventsForDate(NSDate())
        {
            return events
        }
        
        return [NSDate : [EKEvent]]()
    }
    
    //returns a model with given date's month
    private func monthlyEventsForDate(date: NSDate) -> [NSDate : [EKEvent]]?
    {
        if let startOfMonth = date.startOfMonth(), endOfMonth = date.endOfMonth()
        {
            if let monthEvents = model.fetchEvents(fromDate: startOfMonth, toDate: endOfMonth)
            {
                let allEvents = Array(monthEvents)
                var model = [NSDate : [EKEvent]]()
                
                for event in allEvents
                {
                    model = addEventToEventsModel(event, eventsModel: model)
                }
                
                //sorting
                for (key , var monthlyEvents) in model
                {
                    sort(&monthlyEvents, {
                        $0.startDate < $1.startDate
                    })
                    
                    model[key] = monthlyEvents
                }
                
                return model
            }
        }
        
        return nil
    }
    
    private func addEventToEventsModel(event: EKEvent, var eventsModel: [NSDate : [EKEvent]]) -> [NSDate : [EKEvent]]
    {
        let keyForEvent = eventsModelKeyForEvent(event)
        if var eventsOnMonth = eventsModel[keyForEvent]
        {
            eventsOnMonth.append(event)
            eventsModel[keyForEvent] = eventsOnMonth
        }
        else
        {
            eventsModel[keyForEvent] = [event]
        }
        
        return eventsModel
    }
    
    private func eventsModelKeyForEvent(event: EKEvent) -> NSDate
    {
        return eventsModelKeyForDate(event.startDate)
    }
    
    private func eventsModelKeyForDate(date: NSDate) -> NSDate
    {
        return date.startOfMonth()!
    }
    
    private func sortEvents(events: Set<EKEvent>) -> [EKEvent]
    {
        return [EKEvent]()
    }
    
    func numberOfMonths() -> Int
    {
        return count(eventsModel.keys)
    }
    
    func numberOfActiveDaysInSection(section: Int) -> Int
    {
        let monthDate = monthDateForSection(section)
        if let eventsOnMonth = eventsModel[monthDate]
        {
            return count(eventsOnMonth)
        }
        
        return 0
    }
    
    func eventForIndexPath(indexPath: NSIndexPath) -> EKEvent
    {
        let monthForIndexPath = monthDateForSection(indexPath.section)
        let eventsForMonth = self.eventsModel[monthForIndexPath]!
        let event = eventsForMonth[indexPath.row]
        return event
    }
    
    private func monthDateForSection(section: Int) -> NSDate
    {
        return Array(self.eventsModel.keys).sorted({ $0 < $1 })[section]
    }
    
    func shouldHideDateOnEvent(event: EKEvent, atIndexPath indexPath: NSIndexPath) -> Bool
    {
        if indexPath.row == 0 // first event for month
        {
            return false
        }
        
        let previousEventIndexPath = NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)
        let previousEvent = eventForIndexPath(previousEventIndexPath)
        return event.startDate.isOnTheSameDayAs(previousEvent.startDate)
    }
    
    func middleIndexPath(indexPaths: [NSIndexPath]) -> NSIndexPath
    {
        let middleIndex = indexPaths.count / 2
        return indexPaths[middleIndex]
    }
    
    func indexPathForDate(date: NSDate) -> NSIndexPath
    {
        if !isDateLoaded(date)
        {
            if let events = monthlyEventsForDate(date)
            {
                updateEventsModelWithEvents(events)
            }
        }
        
        return nearestIndexPathForDate(date)
    }
    
    private func nearestIndexPathForDate(date: NSDate) -> NSIndexPath
    {
        let keyForDate = eventsModelKeyForDate(date)
        let monthSection = findNearestMonthIndexToDate(date, inMonths: Array(self.eventsModel.keys))!
        var eventRow: Int
        
        if let monthEvents = eventsModel[keyForDate]
        {
            eventRow = findNearestEventIndexToDate(date, inEvents: monthEvents)!
        }
        else
        {
            let monthDate = monthDateForSection(monthSection)
            eventRow = eventsModel[monthDate]!.count - 1
        }
        
        return NSIndexPath(forRow: eventRow, inSection: monthSection)
    }
    
    private func findNearestMonthIndexToDate(date: NSDate, inMonths months: [NSDate]) -> Int?
    {
        let sortedMonths = months.sorted({ $0 < $1 })
        let dateMonthRepresentation = eventsModelKeyForDate(date)
        
        for index in 0...(count(sortedMonths) - 1)
        {
            if dateMonthRepresentation <= sortedMonths.first
            {
                return 0
            }
            
            if dateMonthRepresentation >= sortedMonths.last
            {
                return count(sortedMonths) - 1
            }
            
            if (sortedMonths[index] <= dateMonthRepresentation) && (dateMonthRepresentation < sortedMonths[index + 1])
            {
                return index
            }
        }
        
        return nil
    }
    
    private func findNearestEventIndexToDate(date: NSDate, inEvents events: [EKEvent]) -> Int?
    {
        let eventStartDates = events.map{ $0.startDate }
        
        for index in 0...(count(eventStartDates) - 1)
        {
            if date <= eventStartDates.first
            {
                return 0
            }
            
            if date >= eventStartDates.last
            {
                return count(eventStartDates) - 1
            }
            
            if (eventStartDates[index] <= date) && (date < eventStartDates[index + 1])
            {
                return index
            }
        }
        
        return nil
    }
    
    func saveNewEvent(event: EKEvent)
    {
        let eventDate = event.startDate
        let keyForNewEvent = eventsModelKeyForDate(eventDate)
        if var currentEvents = eventsModel[keyForNewEvent]
        {
            currentEvents.append(event)
            currentEvents.sort{ $0.startDate < $1.startDate }
            eventsModel[keyForNewEvent] = currentEvents
            
            return
        }
        
        eventsModel[keyForNewEvent] = [event]
    }
    
    func removeEvent(event: EKEvent)
    {
        let eventDate = event.startDate
        let keyForNewEvent = eventsModelKeyForDate(eventDate)
        if var currentEvents = eventsModel[keyForNewEvent]
        {
            if let index = find(currentEvents, event)
            {
                currentEvents.removeAtIndex(index)
                currentEvents.sort{ $0.startDate < $1.startDate }
                eventsModel[keyForNewEvent] = currentEvents
            }
        }
    }
    
    //this update is forced, i.e. it assumes that a month key, if exists in eventsModel is no longer valid and replaced it with the new one given as part of the function argument
    private func updateEventsModelWithEvents(events: [NSDate : [EKEvent]])
    {
        for (key , var monthlyEvents) in events
        {
            eventsModel[key] = monthlyEvents
        }
    }
    
    private func isDateLoaded(date: NSDate) -> Bool
    {
        return eventsModel[eventsModelKeyForDate(date)] != nil
    }
}






