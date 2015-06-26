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

    @IBOutlet weak var calendarMenuView: JTCalendarMenuView!
    @IBOutlet weak var calendarContentView: JTCalendarContentView!
    @IBOutlet weak var calendarContentViewHeight: NSLayoutConstraint!
    
    var calendarUIManager: JTCalendar
    var calendarModel: Calendar
    
    // MARK: - life cycle
    
    required init(coder aDecoder: NSCoder)
    {
        self.calendarUIManager = JTCalendar()
        self.calendarModel = Calendar()
        super.init(coder: aDecoder)
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
        eventEditVC.eventStore = Calendar.eventStore
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
        calendarModel.saveEvent(title: event.title, startDate: event.startDate, endDate: event.endDate, location: event.location)
        calendarUIManager.reloadData()
    }
    
    private func deleteEvent(event: EKEvent)
    {
        //todo: implement
    }
}

extension CalendarViewController: JTCalendarDataSource{
    
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool
    {
        //todo: implement
        return true
    }
    
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!)
    {
        //todo: implement
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





