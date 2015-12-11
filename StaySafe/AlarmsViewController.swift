//
//  AlarmsViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/8/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import EventKit
import MapKit

class AlarmsViewController: UIViewController {
    var coreLoc = CoreLoc()
    
    @IBOutlet weak var calTextField :UITextField!
    @IBOutlet var addressSearchBar: UITextField!
    @IBOutlet weak var calstartDatePicked :UIDatePicker!
    @IBOutlet var friendsMap: MKMapView!
    
    let eventStore = EKEventStore()
    
    
    var currentEvent :EKEvent?
    var editingEvent :EKEvent!
    
    //MARK: - Permission Methods
    func requestAccessToEKType (type: EKEntityType) {
        eventStore.requestAccessToEntityType(type) { (accessGranted, error) -> Void in
            if (accessGranted) {
                print("granted")
            } else {
                print("not granted")
            }
        }
    }
    
    func checkEKAuthorizationStatus (type: EKEntityType) {
        let status = EKEventStore.authorizationStatusForEntityType(type)
        switch status {
        case .NotDetermined:
            print("not Determined")
            requestAccessToEKType(type)
        case .Authorized:
            print("authorized")
        case .Restricted, .Denied:
            print("restricted")
        }
        
    }
    
    @IBAction func createAlarm(sender: UIBarButtonItem) {
        print("address should be \(addressSearchBar!.text!)")
        coreLoc.getLatLonFromAddress(addressSearchBar!.text!)
    }
    
    @IBAction func restrictDatePickerUse() {
        if (calstartDatePicked.date.earlierDate(NSDate()) == calstartDatePicked.date) {
            calstartDatePicked.date = NSDate()
        }
    }
    
    func checkCalEventsOverlap(start: NSDate, end: NSDate) -> Bool {
        let calendars = eventStore.calendarsForEntityType(.Event)
        let predicate = eventStore.predicateForEventsWithStartDate(start, endDate: end, calendars: calendars)
        let testArray = eventStore.eventsMatchingPredicate(predicate)
        print("Count: \(testArray.count)")
        return (testArray.count == 0)
    }
    
    func searchCalForEvent(start: NSDate, end: NSDate) -> EKEvent {
        let calendars = eventStore.calendarsForEntityType(.Event)
        let predicate = eventStore.predicateForEventsWithStartDate(start, endDate: end, calendars: calendars)
        let testArray = eventStore.eventsMatchingPredicate(predicate)
        print("Count: \(testArray.count)")
        return testArray[0]
    }
    
    func returnLocFromSearch() {
        print("title should be \(calTextField.text!)")
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        if calTextField.text!.characters.count > 0 {
            reminder.title = calTextField.text!
            let alarm = EKAlarm(absoluteDate: calstartDatePicked.date)
            reminder.addAlarm(alarm)
            let locAlarm = EKAlarm()
            let ekLoc = EKStructuredLocation(title: calTextField.text!)
            let loc = coreLoc.locFromAddress
            
            let getLat: CLLocationDegrees = loc.latitude
            let getLon: CLLocationDegrees = loc.longitude
            let convertedLoc: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
            

            ekLoc.geoLocation = convertedLoc
            ekLoc.radius = 100
            locAlarm.structuredLocation = ekLoc
            locAlarm.proximity = .Enter
            reminder.addAlarm(locAlarm)
            do {
                try eventStore.saveReminder(reminder, commit: true)
            } catch {
                print("got error")
            }
        } else {
            let alert = UIAlertController(title: "Enter reminder Name!", message: "You need to pick a reminder title to create a reminder", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        checkEKAuthorizationStatus(.Event)
        checkEKAuthorizationStatus(.Reminder)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "returnLocFromSearch", name: "gotLocFromSearch", object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
