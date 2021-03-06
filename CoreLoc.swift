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
    var locFromAddress = CLLocationCoordinate2D()
    
    
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
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        userLocation = locations[0]
        let long = userLocation.coordinate.longitude
        let lat = userLocation.coordinate.latitude
        let point = PFGeoPoint(latitude: lat, longitude: long)
        currentPoint = point
        
        if currentPoint.distanceInMilesTo(mostRecentPoint) > 0.02 {
            if currentPoint != mostRecentPoint {
                if let currentUser = PFUser.currentUser() {
                    let newLoc = PFObject(className:"UserLocHistory")
                    newLoc["user"] = currentUser.username!
                    let newACL = PFACL()
                    for group in groupsArray {
                        mostRecentPoint = currentPoint
                        newLoc["parent"] = group
                        newLoc["currentLoc"] = point
                        
                        for user in usersArray {
                            print("\(user.username) in \(group["groupName"])")
                            newACL.setReadAccess(true, forUser: user)
                            newACL.setWriteAccess(true, forUser: user)
                        }
                    }
                    newLoc.ACL = newACL
                    newLoc.saveEventually({ (success, error) -> Void in
                        if success {
                            print("Successfully saved a pin")
                        } else {
                            print("error saving")
                        }
                    })
                }
                counter++
                testString = ("\(counter) \(point.latitude) \(point.longitude)")
                print("\(counter) \(point.latitude) \(point.longitude)")
            }
        }
        otherCounter++
        print("other counter: \(otherCounter) \(point.latitude) \(point.longitude)")
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
    func getLocFromAddress(address: String, map: MKMapView) {
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
    
    func getLatLonFromAddress(address: String) {
        print("got inside getLatLonFromAddress")
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            print("got inside block")
            if((error) != nil){
                print("Error", error)
            } else if let placemark = placemarks?.first {
                //these are the coordinates i will feed into the routing methods
                let coordinates:CLLocationCoordinate2D = placemark.location!.coordinate
                self.locFromAddress = coordinates
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "gotLocFromSearch", object: nil))
                }
                print("long: \(coordinates.longitude) lat: \(coordinates.latitude)")
            }
        })
    }
    
    
}
