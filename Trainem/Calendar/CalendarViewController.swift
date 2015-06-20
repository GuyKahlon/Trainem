//
//  CalendarViewController.swift
//  Trainem
//
//  Created by idan haviv on 6/20/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit

class CalendarViewController: UIViewController {

    @IBOutlet weak var calendarMenuView: JTCalendarMenuView!
    @IBOutlet weak var calendarContentView: JTCalendarContentView!
    @IBOutlet weak var calendarContentViewHeight: NSLayoutConstraint!
    
    var calendar: JTCalendar
    
    // MARK: - life cycle
    
    required init(coder aDecoder: NSCoder)
    {
        self.calendar = JTCalendar()
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        setUpCalendar()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        calendar.reloadData()
    }
    
    func setUpCalendar()
    {
        let calendarAppearance = calendar.calendarAppearance()
        calendarAppearance.calendar().firstWeekday = 2; // Sunday == 1, Saturday == 7
        calendarAppearance.dayCircleRatio = 9/10
        calendarAppearance.ratioContentMenu = 1
        calendar.menuMonthsView = calendarMenuView
        calendar.contentView = calendarContentView
        calendar.dataSource = self
    }
    
    // MARK: - bottuns callback
    
    @IBAction func todayButtonAction(sender: AnyObject)
    {
        calendar.currentDate = NSDate()
    }
    
    @IBAction func changeModeAction(sender: AnyObject)
    {
        calendar.calendarAppearance().isWeekMode = !calendar.calendarAppearance().isWeekMode
        exampleTransition()
    }
    
    func exampleTransition()
    {
        var newHeight: CGFloat = 300
        
        if (calendar.calendarAppearance().isWeekMode)
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
            self.calendar.reloadAppearance()
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                self.calendarContentView.layer.opacity = 1
            })
        }
    }
}

extension CalendarViewController: JTCalendarDataSource{
    
    func calendarHaveEvent(calendar: JTCalendar!, date: NSDate!) -> Bool {
        return true
    }
    func calendarDidDateSelected(calendar: JTCalendar!, date: NSDate!) {
        
    }
}







