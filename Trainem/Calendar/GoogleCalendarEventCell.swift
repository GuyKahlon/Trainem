//
//  GoogleCalendarEventCell.swift
//  Trainem
//
//  Created by idan haviv on 7/16/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit
import EventKit

class GoogleCalendarEventCell: UITableViewCell {

    var event: EKEvent?
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventTimeLabel: UILabel!
    @IBOutlet weak var dayInMonthLabel: UILabel!
    @IBOutlet weak var dayInWeekLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        dayInWeekLabel.hidden = true
        dayInMonthLabel.hidden = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func cleanBeforeReuse()
    {
        eventTitleLabel.text = nil
        eventTimeLabel.text = nil
        
        dayInWeekLabel.hidden = true
        dayInMonthLabel.hidden = true
        
        self.event = nil
    }
    
    func updateEventDetails(event: EKEvent, hideDate: Bool)
    {
        self.event = event
        eventTitleLabel.text = event.title
        eventTimeLabel.text = event.startDate.description
        
        if hideDate == false
        {
            dayInMonthLabel.attributedText = NSAttributedString(string: event.startDate.dayInMonth().description)
            dayInMonthLabel.hidden = false
            dayInWeekLabel.attributedText = NSAttributedString(string: event.startDate.threeLetterDayInWeekString())
            dayInWeekLabel.hidden = false
        }
        
    }
}
