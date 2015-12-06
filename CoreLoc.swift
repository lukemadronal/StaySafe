//  CoreLoc.swift
//  StaySafe
//
//  Created by Luke Madronal on 11/30/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.

import UIKit
import CoreLocation
import Parse

class CoreLoc: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = CoreLoc()
    var locationManager = CLLocationManager()
    var dataManager = DataManager()
    
    var groupsArray = [PFObject]()
    var usersArray = [PFUser]()
    var counter = 0
    var otherCounter = 0
    var testString = ""
    var currentPoint = PFGeoPoint()
    var mostRecentPoint = PFGeoPoint()
    
    
    override init() {
        super.init()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        //locationManager.pausesLocationUpdatesAutomatically = true
        //locationManager.allowsBackgroundLocationUpdates = true
        locationManager.allowDeferredLocationUpdatesUntilTraveled(100, timeout: 60*2)
        locationManager.startUpdatingLocation()
    }
    
    func sendGroupsToCoreLoc(groups: [PFObject]) {
        groupsArray = groups
    }
    
    func sendUsersToCoreLoc(users: [PFUser]) {
        usersArray = users
    }
    
    func locationManagerDidPauseLocationUpdates(manager: CLLocationManager) {
        print("did print")
    }
    
    func locationManagerDidResumeLocationUpdates(manager: CLLocationManager) {
        print("did resume")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let userLocation:CLLocation = locations[0]
        let long = userLocation.coordinate.longitude;
        let lat = userLocation.coordinate.latitude;
        let point = PFGeoPoint(latitude: lat, longitude: long)
        currentPoint = point
        
        if currentPoint != mostRecentPoint {
            mostRecentPoint = currentPoint
            if let currentUser = PFUser.currentUser() {
                let newLoc = PFObject(className:"UserLocHistory")
                newLoc["user"] = currentUser.username!
                for group in groupsArray {
                    newLoc["parent"] = group
                    newLoc["currentLoc"] = point
                    let newACL = PFACL()
                    for user in usersArray {
                        if user == currentUser {
                            newACL.setReadAccess(true, forUser: currentUser)
                            newACL.setWriteAccess(true, forUser: currentUser)
                        } else {
                            newACL.setReadAccess(true, forUser: user)
                            newACL.setWriteAccess(false, forUser: user)
                        }
                    }
                    newLoc.ACL = newACL
                    newLoc.saveEventually()
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "locationUpdated", object: nil))
            }
            counter++
            testString = ("\(counter) \(point.latitude) \(point.longitude)")
            print("\(counter) \(point.latitude) \(point.longitude)")
        }
        otherCounter++
        //print("other counter:\(otherCounter) \(point.latitude) \(point.longitude)")
//        Do What ever you want with it
    }
}
