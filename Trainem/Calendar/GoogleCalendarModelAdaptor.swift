//
//  GoogleCalendarModelAdapter.swift
//  Trainem
//
//  Created by idan haviv on 7/16/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation
import EventKit

protocol GoogleCalendarModelAdaptorDelegate{
    func modelHasUpdated()
}
/* 
    this is a GoogleCalendarModel adapter to be used by a table view controller
    the model is a dictionary with NSDate as keys that represent a whole month. that date would be
    the startOfMonth() NSDate extension return value. eventsModel values are sorted EKEvents arrays
*/
class GoogleCalendarModelAdaptor {
    
    private let model: Calendar
    var delegate: GoogleCalendarModelAdaptorDelegate?
    
    //events model keys are NSDate that represent a month, and values are all events on that month
    private var eventsModel = [NSDate : [EKEvent]]()
    
    init(model: Calendar)
    {
        self.model = model
        instantiateEventsModel()
    }
    
    func instantiateEventsModel()
    {
        monthlyEventsForDate(NSDate(), completionBlock: { (fetchedEvents, error) in
            if let fetchedEvents = fetchedEvents
            {
                self.eventsModel = self.constructModelFromEvents(fetchedEvents)
                
                if let delegate = self.delegate
                {
                    delegate.modelHasUpdated()
                }
            }
        })
    }
    
    //returns a model with given date's month if one is cached or executes the completion block after fetching uncached events
    private func monthlyEventsForDate(date: NSDate, completionBlock: FetchEventsBlock)
    {
        if let startOfMonth = date.startOfMonth(), endOfMonth = date.endOfMonth()
        {
            if model.dateRangeIsCached(fromDate: startOfMonth, toDate: endOfMonth)
            {
                let monthlyEvents = model.cachedEvents(fromDate: startOfMonth, toDate: endOfMonth)
                completionBlock(fetchedEvents: monthlyEvents, error: nil)
                return
            }
            
            model.fetchEvents(fromDate: startOfMonth, toDate: endOfMonth, completionBlock: completionBlock)
        }
    }
    
    //if events are nil or no events, creates an empty entry in the model for consistency
    func constructModelFromEvents(events: Set<EKEvent>?, atDate: NSDate) -> [NSDate : [EKEvent]]
    {
        if let events = events where events.count > 0
        {
            return constructModelFromEvents(events)
        }
        
        let atDateKey = eventsModelKeyForDate(atDate)
        var model = [atDateKey : [EKEvent]()]
        return model
    }
    
    //changes the data structure to one that is appropriate to serve as class model
    func constructModelFromEvents(events: Set<EKEvent>) -> [NSDate : [EKEvent]]
    {
        let allEvents = Array(events)
        var model = [NSDate : [EKEvent]]()
        
        for event in allEvents
        {
            model = addEventToEventsModel(event, eventsModel: model)
        }
        
        //sorting
        for (key , var eventsForKey) in model
        {
            sort(&eventsForKey, {
                $0.startDate < $1.startDate
            })
            
            model[key] = eventsForKey
        }
        
        return model
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
    
    //checks if visible index paths are getting near the ends of loaded events on model and if so, loads next/past events
    func reloadDataForIndexPathsAtBottom(firstVisibleIndexPath: NSIndexPath, lastVisibleIndexPath: NSIndexPath)
    {
        let lastIndexPath = lastIndexPathForModel()
        
        if lastVisibleIndexPath.section <= lastIndexPath.section && lastVisibleIndexPath.row > lastIndexPath.row - 10
        {
            let keys = [NSDate](eventsModel.keys)
            let sortedKeys = keys.sorted({ $0 < $1})
            fetchNextMonthEvents(sortedKeys.last!)
        }
    }
    
    //checks if visible index paths are getting near the ends of loaded events on model and if so, loads next/past events; fetches next month's events as indicated by the model and not the UI, i.e. the UI doesn't have to present a few month's events for there are no events on those dates
    func reloadDataForIndexPathsAtTop(firstVisibleIndexPath: NSIndexPath, lastVisibleIndexPath: NSIndexPath)
    {
        if firstVisibleIndexPath.section == 0 && firstVisibleIndexPath.row < 10
        {//getting near the top of events in model
            let keys = [NSDate](eventsModel.keys)
            let sortedKeys = keys.sorted({ $0 < $1})
            fetchPriorMonthEvents(sortedKeys.first!)
        }
    }
    
    //checks if visible index paths are getting near the ends of loaded events on model and if so, loads next/past events; fetches next month's events as indicated by the model and not the UI, i.e. the UI doesn't have to present a few month's events for there are no events on those dates
    private func fetchNextMonthEvents(toDate: NSDate)
    {
        let currentDateComponents = Calendar.defaultCalendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: toDate)
        currentDateComponents.month += 1
        let dateInNextMonth = Calendar.defaultCalendar.dateFromComponents(currentDateComponents)!
        monthlyEventsForDate(dateInNextMonth, completionBlock: { (fetchedEvents, error) -> () in
            let fetchedEventsModel = self.constructModelFromEvents(fetchedEvents, atDate: dateInNextMonth)
            self.updateEventsModelWithEvents(fetchedEventsModel)
            self.delegate?.modelHasUpdated()
        })
    }
    
    private func fetchPriorMonthEvents(toDate: NSDate)
    {
        let currentDateComponents = Calendar.defaultCalendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: toDate)
        currentDateComponents.month -= 1
        let dateInPreviousMonth = Calendar.defaultCalendar.dateFromComponents(currentDateComponents)!
        monthlyEventsForDate(dateInPreviousMonth, completionBlock: { (fetchedEvents, error) -> () in
            
            let fetchedEventsModel = self.constructModelFromEvents(fetchedEvents, atDate: dateInPreviousMonth)
            self.updateEventsModelWithEvents(fetchedEventsModel)
            self.delegate?.modelHasUpdated()
        })
    }
    
    private func lastIndexPathForModel() -> NSIndexPath
    {
        let keys = [NSDate](eventsModel.keys)
        let sortedKeys = keys.sorted({ $0 < $1})
        let lastSection = sortedKeys.count - 1

        let lastMonth = sortedKeys.last!
        
        let lastRow = eventsModel[lastMonth]!.count
        let indexPath = NSIndexPath(forRow: lastRow, inSection: lastSection)
        return indexPath
        
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
    
    func numberOfMonthsWithEventsOnThem() -> Int
    {
        let allMonths = Array(eventsModel.keys)
        let filteredMonths = allMonths.filter(
            {
                if let eventOnMonth = self.eventsModel[$0] where eventOnMonth.count > 0
                {
                    return true
                }
                
                return false
        })
        
        return filteredMonths.count
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
    
    //load dates in a month batch
    func loadDate(date: NSDate, block: FetchEventsBlock)
    {
        if !isDateLoaded(date)
        {
            monthlyEventsForDate(date, completionBlock: { (fetchedEvents, error) -> () in
                if let fetchedEvents = fetchedEvents where fetchedEvents.count > 0
                {
                    let fetchedEventsModel = self.constructModelFromEvents(fetchedEvents)
                    self.updateEventsModelWithEvents(fetchedEventsModel)
                }
                
                block(fetchedEvents: fetchedEvents, error: nil)
            })
            return
        }
        
        block(fetchedEvents: nil, error: nil)
    }
    
    func indexPathForDate(date: NSDate) -> NSIndexPath
    {
        if !isDateLoaded(date)
        {
            monthlyEventsForDate(date, completionBlock: { (fetchedEvents, error) in
                
                if let fetchedEvents = fetchedEvents
                {
                    self.updateEventsModelWithEvents(self.constructModelFromEvents(fetchedEvents))
                }
                
                //todo: log error
            })
        }
        
        return nearestIndexPathForDate(date)
    }
    
    private func nearestIndexPathForDate(date: NSDate) -> NSIndexPath
    {
        let keyForDate = eventsModelKeyForDate(date)
        let monthSection = findNearestMonthIndexToDate(date, inMonths: Array(self.eventsModel.keys))!
        var eventRow: Int
        
        if let monthEvents = eventsModel[keyForDate] where monthEvents.count > 0
        {
            eventRow = findNearestEventIndexToDate(date, inEvents: monthEvents)!
        }
        else
        {
            eventRow = 0
        }
        
        return NSIndexPath(forRow: eventRow, inSection: monthSection)
    }
    
    //months with no events aren't presented and so aren't counted in index path order
    private func findNearestMonthIndexToDate(date: NSDate, inMonths months: [NSDate]) -> Int?
    {
        let filteredMonths = months.filter({
            if let eventOnMonth = self.eventsModel[$0] where eventOnMonth.count > 0
            {
                return true
            }
            
            return false
        })
        
        let sortedMonths = filteredMonths.sorted({ $0 < $1 })
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
        if events.count == 0
        {
            return nil
        }
        
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
    
    func isDateLoaded(date: NSDate) -> Bool
    {
        return eventsModel[eventsModelKeyForDate(date)] != nil
    }
}






