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
    the startOfMonth() NSDate extension return value
*/
class GoogleCalendarModelAdaptor {
    
    private let model: Calendar
    
    //events model keys are NSDate that represent a month, and values are all events on that month
    private var eventsModel = [NSDate : [EKEvent]]()
    
    init(model: Calendar)
    {
        self.model = model
        let currentMonthEvents = model.fetchCurrentMonthEvents()
        if let currentMonthEvents = currentMonthEvents
        {
            eventsModel = constructModel(currentMonthEvents)
        }
        else
        {
            //todo: log error fetching events
        }
    }
    
    private func constructModel(events: Set<EKEvent>) -> ([NSDate : [EKEvent]])
    {
        let allEvents = Array(events)
        var model = [NSDate : [EKEvent]]()
        
        for event in allEvents
        {
            model = addEventToEventsModel(event, eventsModel: model)
        }
        
        for (key , var monthlyEvents) in model
        {
            sort(&monthlyEvents, {
                $0.startDate < $1.startDate
            })
            
            model[key] = monthlyEvents
        }
        
        return model
    }
    
    private func addEventToEventsModel(event: EKEvent, var eventsModel: [NSDate : [EKEvent]]) -> [NSDate : [EKEvent]]
    {
        let eventStartOfMonthDate = event.startDate.startOfMonth()!
        if var eventsOnMonth = eventsModel[eventStartOfMonthDate]
        {
            eventsOnMonth.append(event)
            eventsModel[eventStartOfMonthDate] = eventsOnMonth
        }
        else
        {
            eventsModel[eventStartOfMonthDate] = [event]
        }
        
        return eventsModel
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
}