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
    
    @IBOutlet var friendsMap: MKMapView!
    @IBOutlet var addressSearchBar: UISearchBar!
    
    func incrementSkip() {
        dataManager.increment++
        dataManager.queryUserLocHistory()
    }
    
    func dataFromParseRecievedVC() {
        print("count is \(dataManager.pfGeoPointCount)")
        print("%: \(dataManager.pfGeoPointCount % 200)")
        dataManager.queryUserLocHistory()
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
        dataManager.currentUserForLocHistory = currentUser
        dataManager.countUserLocHistory()
        dataManager.pfGeoPointCount = 0
        dataManager.increment = 0
        dataManager.friendsMap = friendsMap
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
