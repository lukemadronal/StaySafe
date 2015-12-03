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
    
    var groupsArray = [PFObject]()
    
    override init() {
        super.init()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func sendGroupsToCoreLoc(groups: [PFObject]) {
        groupsArray = groups
        print("CORELOC: groupArray is \(groupsArray)")
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0]
        let long = userLocation.coordinate.longitude;
        let lat = userLocation.coordinate.latitude;
        let point = PFGeoPoint(latitude: lat, longitude: long)
        if let currentUser = PFUser.currentUser() {
            print("unwrapped current User")
            
            for group in groupsArray {
                let newLoc = PFObject(className:"UserLocHistory")
                newLoc["user"] = currentUser.username!
                newLoc["parent"] = group
                newLoc["currentLoc"] = point
                newLoc.saveEventually()
            }
            
//            if var breadCrumbs = newLoc["breadCrumbs"] as? [PFGeoPoint] {
//                print("unwrapped the breadCrumbs array")
//                breadCrumbs.append(point)
//                newLoc["breadCrumbs"] = breadCrumbs
//                newLoc.saveEventually()
//            } else {
//                print("the breadCrumbs array didnt unwrapp creating new one ")
//                var breadCrumbs = [PFGeoPoint]()
//                breadCrumbs.append(point)
//                newLoc["breadCrumbs"] = breadCrumbs
//                newLoc.saveEventually()
//            }
            
        }
//        Do What ever you want with it
    }
}
