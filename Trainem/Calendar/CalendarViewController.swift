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
        self.calendarModel = Calendar()
        self.calendarModel.requestCalendarPermissionFromUserAndFetchEvents()
        self.calendarUIManager = JTCalendar()
        self.googleCalendarModelAdaptor = GoogleCalendarModelAdaptor(model: self.calendarModel)
        
        super.init(coder: aDecoder)
        
        self.googleCalendarModelAdaptor.delegate = self
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        scrollGoogleCalendarToDate(NSDate(), animated: false)
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
        calendarUIManager.delegate = self
    }
    
    private func scrollGoogleCalendarToDate(date: NSDate, animated: Bool)
    {
        googleCalendarModelAdaptor.loadDate(date, block: { (fetchedEvents, error) in
            
            if error == nil
            {
                let indexPath = self.googleCalendarModelAdaptor.indexPathForDate(date)
                self.tableView.reloadData()
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: animated)
            }
        })
    }
    
    // MARK: - bottuns callback
    
    @IBAction func todayButtonAction(sender: AnyObject)
    {
        scrollGoogleCalendarToDate(NSDate(), animated: true)
        calendarUIShowDate(NSDate())
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
        calendarModel.saveEventToCalendar(title: event.title, startDate: event.startDate, endDate: event.endDate, location: event.location) { (savedEvent, error) -> () in
            
            if error == nil
            {
                self.googleCalendarModelAdaptor.saveNewEvent(event)
                self.calendarUIManager.reloadData()
                self.tableView.reloadData()
            }
        }
    }
    
    private func deleteEvent(event: EKEvent)
    {
        calendarModel.removeEventFromCalendar(event, completionBlock: { (removedEvent, error) -> () in
            
            if error == nil
            {
                self.googleCalendarModelAdaptor.removeEvent(event)
                self.calendarUIManager.reloadData()
                self.tableView.reloadData()
            }
        })
    }
}

//the data source for the calendar UI
extension CalendarViewController: JTCalendarDataSource{
    
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool
    {
        if calendarModel.dateRangeIsCached(fromDate: date, toDate: date)
        {
            let dailyEvents = calendarModel.cachedEvents(fromDate: date, toDate: date)
            if dailyEvents.count > 0
            {
                return true
            }
            
            return false
        }
        
        //fetch events and then update model and UI
        calendarModel.fetchEventsOnDay(date, completionBlock: { (fetchedEvents, error) -> () in
            self.calendarUIManager.reloadData()

            //todo: maybe add calendarUIManager.reloadAppearance()
        })
        
        return false
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!)
    {
        scrollGoogleCalendarToDate(date, animated: true)
    }
}

extension CalendarViewController: JTCalendarDelegate{
    
    func dateHasUpdatedWithDate(date: NSDate!)
    {
        scrollGoogleCalendarToDate(date, animated: true)
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
    
    //todo: maybe needs to make it more efficient because it gets a little stuck when dragging between months
//    func scrollViewDidEndDecelerating(scrollView: UIScrollView)
//    {
//        updateGoogleCalendarUI(scrollView)
//    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        updateGoogleCalendarUI(scrollView)
    }
    
    private func updateGoogleCalendarUI(scrollView: UIScrollView)
    {
        if let table = scrollView as? UITableView
        {
            if let visibleIndexPaths = table.indexPathsForVisibleRows() as? [NSIndexPath]
            {
                let middleIndexPath = googleCalendarModelAdaptor.middleIndexPath(visibleIndexPaths)
                let middleEvent = googleCalendarModelAdaptor.eventForIndexPath(middleIndexPath)
                calendarUIShowDate(middleEvent.startDate)
                
                if (scrollView.contentOffset.y <= 0)
                {//scrollView is at the top
                    googleCalendarModelAdaptor.reloadDataForIndexPathsAtTop(visibleIndexPaths.first!, lastVisibleIndexPath: visibleIndexPaths.last!)
                }
                else
                {
                    googleCalendarModelAdaptor.reloadDataForIndexPathsAtBottom(visibleIndexPaths.first!, lastVisibleIndexPath: visibleIndexPaths.last!)
                }
                
            }
        }
    }
    
    private func calendarUIShowDate(date: NSDate)
    {
        self.calendarUIManager.currentDateSelected = date
        self.calendarUIManager.currentDate = date
        self.calendarUIManager.reloadData()
        self.calendarUIManager.reloadAppearance()
    }
}

extension CalendarViewController: GoogleCalendarModelAdaptorDelegate{
    
    //todo: find a better way to do it
    func modelHasUpdated() {
        if let visibleCells = self.tableView.visibleCells() as? [GoogleCalendarEventCell]
        {
            
            let lastTableViewVisibleDate = visibleCells[visibleCells.count/2].event?.startDate
            self.tableView.reloadData()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.scrollGoogleCalendarToDate(lastTableViewVisibleDate!, animated: false)
            })
        }
    }
}



