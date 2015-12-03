//
//  CoreLoc.swift
//  StaySafe
//
//  Created by Luke Madronal on 11/30/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import CoreLocation
import Parse

class CoreLoc: NSObject, CLLocationManagerDelegate {
    static let sharedInstance = CoreLoc()
    var locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        let userLocation:CLLocation = locations[0]
//        let long = userLocation.coordinate.longitude;
//        let lat = userLocation.coordinate.latitude;
//        print("long is \(long) lat is \(lat)")
//        Do What ever you want with it
    }
}
