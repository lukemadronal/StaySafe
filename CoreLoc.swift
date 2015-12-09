//  CoreLoc.swift
//  StaySafe
//
//  Created by Luke Madronal on 11/30/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.

import UIKit
import CoreLocation
import MapKit
import Parse

class CoreLoc: NSObject, CLLocationManagerDelegate, MKMapViewDelegate {
    static let sharedInstance = CoreLoc()
    var locationManager = CLLocationManager()
    var dataManager = DataManager()
    var userLocation = CLLocation()
    
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
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.allowDeferredLocationUpdatesUntilTraveled(100, timeout: 60*2)
    }
    
    func startLocMonotoring() {
        locationManager.startUpdatingLocation()
    }
    
    func stopLocMonotoring() {
        locationManager.stopUpdatingLocation()
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

        userLocation = locations[0]
        let long = userLocation.coordinate.longitude
        let lat = userLocation.coordinate.latitude
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
            counter++
            testString = ("\(counter) \(point.latitude) \(point.longitude)")
            print("\(counter) \(point.latitude) \(point.longitude)")
        }
        otherCounter++
        //print("other counter:\(otherCounter) \(point.latitude) \(point.longitude)")
//        Do What ever you want with it
    }
    
    
    
    //MARK: - Rounting Methods
    
    func openAppleMaps(point: CLLocationCoordinate2D){
        
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(point.latitude, point.longitude)
        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(MKCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(MKCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "test title"
        mapItem.openInMapsWithLaunchOptions(options)
    }
    
    func route(point: CLLocationCoordinate2D, map: MKMapView) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude), addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude), addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .Walking
        
        let directions = MKDirections(request: request)
        
        directions.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            for route in unwrappedResponse.routes {
                map.addOverlay(route.polyline)
                map.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                for step in route.steps {
                    print(step.instructions)
                }
            }
        }
    }
    
    func getLatLonFromAddress(address: String, map: MKMapView) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            if((error) != nil){
                print("Error", error)
            } else if let placemark = placemarks?.first {
                //these are the coordinates i will feed into the routing methods
                let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                self.openAppleMaps(coordinates)
                self.route(coordinates, map: map)
                print("long: \(coordinates.longitude) lat: \(coordinates.latitude)")
            }
        })
    }
    

}
