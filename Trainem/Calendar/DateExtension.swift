//
//  DateExtension.swift
//  Trainem
//
//  Created by idan haviv on 6/27/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import Foundation

extension NSDate {
    
    func startOfMonth() -> NSDate?
    {
        let currentDateComponents = Calendar.defaultCalendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: self)
        let startOfMonth = Calendar.defaultCalendar.dateFromComponents(currentDateComponents)
        return startOfMonth
    }
    
    func isDateOnTheSameDay(otherDate: NSDate)->Bool
    {
        return NSCalendar.currentCalendar().isDate(self, inSameDayAsDate: otherDate)
    }
    
    func dateByAddingMonths(monthsToAdd: Int) -> NSDate? {
        
        let calendar = NSCalendar.currentCalendar()
        let months = NSDateComponents()
        months.month = monthsToAdd
        
        return calendar.dateByAddingComponents(months, toDate: self, options: nil)
    }
    
    func endOfMonth() -> NSDate? {
        
        let calendar = NSCalendar.currentCalendar()
        if let plusOneMonthDate = dateByAddingMonths(1) {
            let plusOneMonthDateComponents = calendar.components(.CalendarUnitYear | .CalendarUnitMonth, fromDate: plusOneMonthDate)
            
            let endOfMonth = calendar.dateFromComponents(plusOneMonthDateComponents)?.dateByAddingTimeInterval(-1)
            
            return endOfMonth
        }
        
        return nil
    }
    
    func dateWithOutTimeOfDay()->(NSDate)
    {
        let components = NSCalendar.currentCalendar().components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: self)
        let newDate = NSCalendar.currentCalendar().dateFromComponents(components)
        return newDate!
    }
    
    func dateWithBeginningOfDay()->NSDate
    {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay, fromDate: self)
        return calendar.dateFromComponents(components)!
    }
    
    func dateWithEndOfDay()->NSDate
    {
        let calendar = NSCalendar.currentCalendar()
        let components = NSDateComponents()
        components.day = 1
        
        var newDate = calendar.dateByAddingComponents(components, toDate: self.dateWithBeginningOfDay(), options: nil)
        newDate = newDate?.dateByAddingTimeInterval(-1)
        return newDate!
    }
    
    func isGreaterThanDate(dateToCompare : NSDate) -> Bool
    {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedDescending
    }
    
    func isLessThanDateByMoreThanTwoHours(dateToCompare: NSDate) -> Bool
    {
        let calendar = NSCalendar.currentCalendar()
        var components = calendar.components(.CalendarUnitHour, fromDate: self)
        components.hour += 2
        let increasedByTwoHoursDate = calendar.dateFromComponents(components)
        
        return increasedByTwoHoursDate!.isLessThanDate(dateToCompare)
    }
    
    func isGreaterThanDateByMoreThanTwoHours(dateToCompare: NSDate) -> Bool
    {
        let calendar = NSCalendar.currentCalendar()
        var components = calendar.components(.CalendarUnitHour, fromDate: self)
        components.hour -= 2
        let decreasedByTwoHoursDate = calendar.dateFromComponents(components)
        
        return decreasedByTwoHoursDate!.isGreaterThanDate(dateToCompare)
    }
    
    func isLessThanDate(dateToCompare : NSDate) -> Bool
    {
        return self.compare(dateToCompare) == NSComparisonResult.OrderedAscending
    }
    
    func previousDayWithSameTime()->NSDate
    {
        let calendar = NSCalendar.currentCalendar()
        var components = NSDateComponents()
        components.day = -1
        return calendar.dateByAddingComponents(components, toDate: self, options: nil)!
    }
}