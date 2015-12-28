//
//  DataManager.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/3/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import Parse
import MapKit

class DataManager: NSObject {
    static let sharedInstance = DataManager()
    
    var myGroupsArray = [PFObject]()
    var listOfUsers = [PFUser]()
    var userByUsername : PFUser!
    var userByPhoneNumber : PFUser!
    var userToAdd : PFUser!
    var allGroups = [PFObject]()
    var count = 0
    var counter = 0
    var groupsImInCount = Int32()
    var groupsCount = Int32()
    var pfGeoPointCount = Int32()
    var currentGroupName = ""
    
    var friendsMap: MKMapView!
    var increment = 0
    var currentUserForLocHistory : PFUser?
    
    
    func findMyGroups() {
        let query = PFQuery(className:"Groups")
        if let currentUser = PFUser.currentUser() {
            query.whereKey("groupLeaderUsername", equalTo:currentUser.username!)
            query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                if error == nil {
                    // The find succeeded.
                    // Do something with the found objects
                    if let uObjects = objects {
                        self.myGroupsArray = uObjects
                        //print("group name is \(uObjects[0]["groupName"])")
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "receivedDataFromParse", object: nil))
                        }
                    }
                } else {
                    print("Error: \(error!) \(error!.userInfo)")
                }
            }
        }
    }
    
    func getListOfUsers() -> [PFUser] {
        
        return listOfUsers
    }
    
    func queryGroupListToFriendList(group: PFObject) {
        
        listOfUsers.removeAll()
        if let uGroupList = group["groupList"] as? [String] {
            self.counter = 1
            self.count = 0
            //print("unwrapped the group called \(group["groupName"])")
            count = uGroupList.count
            for member in uGroupList {
                let query = PFUser.query()
                query!.whereKey("objectId", equalTo:member)
                query!.findObjectsInBackgroundWithBlock({ (users, error) -> Void in
                    if error == nil {
                        //print(users)
                        if let user = users![0] as? PFUser {
                            if !self.listOfUsers.contains(user) {
                                //print("user \(user.username!)")
                                self.listOfUsers.append(user)
                                self.userToAdd = user
                                self.currentGroupName = group["groupName"] as! String
                                //print("counter is \(self.counter) and the count is \(self.count)")
                                if self.count == self.counter {
                                    //print("the final list of users for \(group["groupName"]) is \(self.listOfUsers))")
                                    dispatch_async(dispatch_get_main_queue()) {
                                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "gotUserList", object: nil))
                                    }
                                }
                                ++self.counter
                            }
                        }
                        
                    } else {
                        print("in queryGroupListToFriendList \(error)")
                    }
                })
            }
            //print("just exited the group for loop")
        }
    }
    
    func queryGroupsImIn() {
        //print("got into query groups im in")
        let query = PFQuery(className:"Groups")
        query.findObjectsInBackgroundWithBlock { (groups, error)-> Void in
            if error == nil {
                //print("about to unwrap groups from query")
                if let uGroups = groups {
                    //print("unwrapped groups about to go into for loop")
                    var myGroups = [PFObject]()
                    for group in uGroups {
                        //print("group name is \(group["groupName"]!)")
                        if group["groupList"].containsObject(PFUser.currentUser()!.objectId!) {
                            myGroups.append(group)
                        }
                    }
                    self.allGroups = myGroups
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "gotGroupsImIn", object: nil))
                    }
                }
            } else {
                print("error in query my groups: \(error!.description)")
            }
        }
    }
    
    func queryUserBasedOnPhoneNumber(phoneNumbers:[String]) {
       // print("got into query phone numbas")
        let query = PFUser.query()
        query!.limit = 1
        query!.whereKey("phoneNumber", containedIn: phoneNumbers)
        query!.findObjectsInBackgroundWithBlock { (users, error) -> Void in
            //print("size of users is \(users!.count)")
            
            if error == nil {
                if users!.count > 0 {
                    if let user = users![0] as? PFUser {
                        self.userByPhoneNumber = user
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "gotUserByPhoneNumber", object: nil))
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "noUserMatchesQuery", object: nil))
                    }
                }
            } else {
                print("error in query based on phone # error is: \(error!.description)")
            }
            
        }
    }
    
    func queryUserByUserName(username :String) {
        let query = PFUser.query()
        query!.whereKey("username", equalTo: username)
        query!.findObjectsInBackgroundWithBlock { (users, error) -> Void in
            if error == nil {
                if users!.count > 0 {
                    if let user = users![0] as? PFUser {
                        self.userByUsername = user
                        dispatch_async(dispatch_get_main_queue()) {
                            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "gotUserByUserName", object: nil))
                        }
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "noUserMatchesQuery", object: nil))
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "noUsernamePopUpErrorMessage", object: nil))
                }
            }
        }
        
    }
    
    func countMyGroups() {
        let query = PFQuery(className:"Groups")
        if let currentUser = PFUser.currentUser() {
            query.whereKey("groupLeaderUsername", equalTo:currentUser.username!)
            query.countObjectsInBackgroundWithBlock({ (count, error) -> Void in
                self.groupsCount = count
                print("my group count is \(self.groupsCount)")
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "receivedDataFromParseVC", object: nil))
                }
            })
        }
    }
    
    func countGroupsImIn() {
        let query = PFQuery(className:"Groups")
        query.countObjectsInBackgroundWithBlock({ (count, error) -> Void in
            self.groupsImInCount = count
            dispatch_async(dispatch_get_main_queue()) {
                NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "countedGroupsImIn", object: nil))
            }
        })
    }
    
    func countUserLocHistory() {
        if let uCurrentUser = currentUserForLocHistory {
            let query = PFQuery(className:"UserLocHistory")
            query.whereKey("user", equalTo:uCurrentUser.username!)
            query.countObjectsInBackgroundWithBlock({ (count, error) -> Void in
                self.pfGeoPointCount = count
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "receivedDataFromParseVC", object: nil))
                }
            })
        }
    }
    
    func queryUserLocHistory() {
        if let uCurrentUser = currentUserForLocHistory {
            let query = PFQuery(className:"UserLocHistory")
            print("current user is \(uCurrentUser.username!)")
            query.whereKey("user", equalTo: uCurrentUser.username!)
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
                print("count / 100 is \(Int(self.pfGeoPointCount / 200))")
                if self.increment < Int(self.pfGeoPointCount / 200) {
                    print("got into bottom loop. inc is \(self.increment)")
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "newSkipCall", object: nil))
                    }
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
    
}
