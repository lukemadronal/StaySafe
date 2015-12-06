//
//  MapViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/3/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import MapKit
import Parse

class MapViewController: UIViewController {
    
    var currentUser = PFUser()
    var pfGeoPointCount = Int32()
    var increment = 0
    
    @IBOutlet var friendsMap: MKMapView!
    
    func countMyGroups() {
        let query = PFQuery(className:"UserLocHistory")
        query.whereKey("user", equalTo:currentUser.username!)
        query.countObjectsInBackgroundWithBlock({ (count, error) -> Void in
            self.pfGeoPointCount = count
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "receivedDataFromParseVC", object: nil))
            }
        })
        
    }
    
    func incrementSkip() {
        increment++
        queryUserLocHistory()
        
    }
    
    func dataFromParseRecievedVC() {
        print("count is \(pfGeoPointCount)")
        print("%: \(pfGeoPointCount % 100)")
        queryUserLocHistory()
    }
    
    
    
    func queryUserLocHistory() {
        let query = PFQuery(className:"UserLocHistory")
        query.whereKey("user", equalTo: currentUser.username!)
        query.limit = 100
        query.skip = Int(100 * increment)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                // Do something with the found objects
                if let uObjects = objects {
                    print("retrieved \(uObjects.count) objects")
                    for geoPoint in uObjects {
                        let geo = geoPoint["currentLoc"]
                        self.annotationsFirstTryTest(geo.latitude, long: geo.longitude, title: geoPoint["createdAt"] as! String)
                    }
                }
            } else {
                print("Error: \(error!) \(error!.userInfo)")
            }
            print("inc is \(self.increment)")
            print("count / 100 is \(Int(self.pfGeoPointCount / 100))")
            if self.increment < Int(self.pfGeoPointCount / 100) {
                print("got into bottom loop. inc is \(self.increment)")
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "newSkipCall", object: nil))
                }
            }
        }
        
    }
    
    
    func annotationsFirstTryTest(lat: Double, long: Double, title: String) {
        let latDelta:CLLocationDegrees = 0.01
        
        let longDelta:CLLocationDegrees = 0.01
        
        let theSpan:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, longDelta)
        let pointLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        
        let region:MKCoordinateRegion = MKCoordinateRegionMake(pointLocation, theSpan)
        friendsMap.setRegion(region, animated: true)
        
        let pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, long)
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = pinLocation
        objectAnnotation.title = title
        self.friendsMap.addAnnotation(objectAnnotation)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecievedVC", name: "receivedDataFromParseVC", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incrementSkip", name: "newSkipCall", object: nil)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        countMyGroups()
        pfGeoPointCount = 0
        increment = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
