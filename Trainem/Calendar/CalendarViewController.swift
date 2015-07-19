//
//  CalendarViewController.swift
//  Trainem
//
//  Created by idan haviv on 6/20/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKitUI

class CalendarViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendarMenuView: JTCalendarMenuView!
    @IBOutlet weak var calendarContentView: JTCalendarContentView!
    @IBOutlet weak var calendarContentViewHeight: NSLayoutConstraint!
    
    var calendarUIManager: JTCalendar
    var calendarModel: Calendar
    var googleCalendarModelAdaptor: GoogleCalendarModelAdaptor
    
    // MARK: - life cycle
    
    required init(coder aDecoder: NSCoder)
    {
        self.calendarUIManager = JTCalendar()
        self.calendarModel = Calendar()
        self.googleCalendarModelAdaptor = GoogleCalendarModelAdaptor(model: self.calendarModel)
        super.init(coder: aDecoder)
        
        self.calendarModel.requestCalendarPermissionFromUserAndFetchEvents()
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setUpCalendarUI()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        calendarUIManager.reloadData()
    }
    
    func setUpCalendarUI()
    {
        let calendarAppearance = calendarUIManager.calendarAppearance()
        calendarAppearance.calendar().firstWeekday = 2; // Sunday == 1, Saturday == 7
        calendarAppearance.dayCircleRatio = 9/10
        calendarAppearance.ratioContentMenu = 1
        calendarUIManager.menuMonthsView = calendarMenuView
        calendarUIManager.contentView = calendarContentView
        calendarUIManager.dataSource = self
    }
    
    // MARK: - bottuns callback
    
    @IBAction func todayButtonAction(sender: AnyObject)
    {
        calendarUIManager.currentDate = NSDate()
    }
    
    @IBAction func changeModeAction(sender: AnyObject)
    {
        calendarUIManager.calendarAppearance().isWeekMode = !calendarUIManager.calendarAppearance().isWeekMode
        exampleTransition()
    }
    
    @IBAction func newEventAction(sender: AnyObject)
    {
        presentEditEventViewController()
    }
    
    private func presentEditEventViewController()
    {
        let eventEditVC = EKEventEditViewController()
        eventEditVC.eventStore = EventKitManager.eventStore
        eventEditVC.editViewDelegate = self
        self.presentViewController(eventEditVC, animated: true) { () -> Void in
            
        }
    }
    
    func exampleTransition()
    {
        var newHeight: CGFloat = 300
        
        if (calendarUIManager.calendarAppearance().isWeekMode)
        {
            newHeight = 75
        }
        
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.calendarContentViewHeight.constant = newHeight
            self.view.layoutIfNeeded()
        })
        
        UIView.animateWithDuration(0.25, animations: { () -> Void in
            self.calendarContentView.layer.opacity = 0
        }) { (finished) -> Void in
            self.calendarUIManager.reloadAppearance()
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.calendarContentView.layer.opacity = 1
            })
        }
    }
    
    private func saveEvent(event: EKEvent)
    {
        calendarModel.saveEventToCalendar(title: event.title, startDate: event.startDate, endDate: event.endDate, location: event.location)
        calendarUIManager.reloadData()
    }
    
    private func deleteEvent(event: EKEvent)
    {
        calendarModel.removeEventFromCalendar(event)
    }
}

//the data source for the calendar UI
extension CalendarViewController: JTCalendarDataSource{
    
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool
    {
        let dailyEvents = calendarModel.fetchEventsOnDay(date)
        if let dailyEvents = dailyEvents where dailyEvents.count > 0
        {
            return true
        }
        
        return false
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!)
    {
        let indexPath = googleCalendarModelAdaptor.indexPathForDate(date)
        tableView.reloadData()
        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: true)
    }
}

extension CalendarViewController: EKEventEditViewDelegate{
    
    func eventEditViewController(controller: EKEventEditViewController!, didCompleteWithAction action: EKEventEditViewAction)
    {
        switch action.value
        {
            case EKEventEditViewActionCanceled.value: break
            case EKEventEditViewActionDeleted.value: deleteEvent(controller.event)
            case EKEventEditViewActionSaved.value: saveEvent(controller.event)
            default: break
        }
        
        
        controller.dismissViewControllerAnimated(true, completion: { () -> Void in
            
        })
    }
}

extension CalendarViewController: UITableViewDataSource{
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //todo: this should return a month's header (image or something)
        return UIView()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if var eventCell = tableView.dequeueReusableCellWithIdentifier("event cell", forIndexPath: indexPath) as? GoogleCalendarEventCell
        {
            eventCell.cleanBeforeReuse()
            let event = googleCalendarModelAdaptor.eventForIndexPath(indexPath)
            let hideEventDateOnCell = googleCalendarModelAdaptor.shouldHideDateOnEvent(event, atIndexPath: indexPath)
            eventCell.updateEventDetails(event, hideDate: hideEventDateOnCell)
            return eventCell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return googleCalendarModelAdaptor.numberOfActiveDaysInSection(section)
    }
    
    //each month is a section
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return googleCalendarModelAdaptor.numberOfMonths()
    }
}

extension CalendarViewController: UITableViewDelegate{
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
    {
        if let table = scrollView as? UITableView
        {
            if let visibleIndexPaths = table.indexPathsForVisibleRows() as? [NSIndexPath]
            {
                let middleIndexPath = googleCalendarModelAdaptor.middleIndexPath(visibleIndexPaths)
                let middleEvent = googleCalendarModelAdaptor.eventForIndexPath(middleIndexPath)
                self.calendarUIManager.currentDateSelected = middleEvent.startDate
                self.calendarUIManager.reloadData()
            }
            
        }
    }
}




