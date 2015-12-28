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
    
    //singletons
    var dataManager = DataManager()
    
    var coreLoc = CoreLoc()
    var currentUser = PFUser()
    var increment = 0
    
    @IBOutlet var friendsMap: MKMapView!
    @IBOutlet var addressSearchBar: UISearchBar!
    
    func incrementSkip() {
        increment++
        queryUserLocHistory()
    }
    
    func dataFromParseRecievedVC() {
        print("count is \(dataManager.pfGeoPointCount)")
        print("%: \(dataManager.pfGeoPointCount % 200)")
        queryUserLocHistory()
    }
    
    func queryUserLocHistory() {
        let query = PFQuery(className:"UserLocHistory")
        print("current user is \(currentUser.username!)")
        query.whereKey("user", equalTo: currentUser.username!)
        query.limit = 200
        query.skip = Int(200 * increment)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                // The find succeeded.
                // Do something with the found objects
                if let uObjects = objects {
                    print("retrieved \(uObjects.count) objects")
                    for geoPoint in uObjects {
                        let geo = geoPoint["currentLoc"]
                        
                        let dateFormatter = NSDateFormatter()
                        dateFormatter.dateFormat = "hh:mm MM/dd/yyyy"
                        let dateTitle = dateFormatter.stringFromDate(geoPoint.createdAt! as NSDate)
                        
                        self.addAnnotationToMapView(geo.latitude, long: geo.longitude, title: dateTitle)
                    }
                }
            } else {
                print("Error: \(error!) \(error!.userInfo)")
            }
            print("inc is \(self.increment)")
            print("count / 100 is \(Int(self.dataManager.pfGeoPointCount / 200))")
            if self.increment < Int(self.dataManager.pfGeoPointCount / 200) {
                print("got into bottom loop. inc is \(self.increment)")
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "newSkipCall", object: nil))
                }
            }
        }
        
    }
    
    
    func addAnnotationToMapView(lat: Double, long: Double, title: String) {
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
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blueColor()
        renderer.lineWidth = 5
        return renderer
    }
    
    func mapView(mapView: MKMapView!,
        viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
            if annotation is MKUserLocation {
                //return nil so map view draws "blue dot" for standard user location
                return nil
            }
            
            let reuseId = "pin"
            
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.canShowCallout = true
                pinView!.animatesDrop = true
                pinView!.pinTintColor = UIColor(red: 125/255, green: 174/255, blue: 255/255, alpha: 1)
            }
            else {
                pinView!.annotation = annotation
            }
            
            return pinView
    }
    
    //MARK: - Interactivity Methods
    
    @IBAction func searchBarPressed(sender: UIBarButtonItem) {
        coreLoc.getLocFromAddress(addressSearchBar!.text!, map: friendsMap)
    }
    
    
    //MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecievedVC", name: "receivedDataFromParseVC", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "incrementSkip", name: "newSkipCall", object: nil)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dataManager.countUserLocHistory()
        dataManager.pfGeoPointCount = 0
        increment = 0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
