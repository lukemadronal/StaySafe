//
//  DataManager.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/3/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import Parse

class DataManager: NSObject {
    static let sharedInstance = DataManager()
    
    var myGroupsArray = [PFObject]()
    var listOfUsers = [PFUser]()
    var userByUsername : PFUser!
    var userToAdd : PFUser!
    var count = 0
    var counter = 0
    
    
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
                        print("group name is \(uObjects[0]["groupName"])")
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
        counter = 0
        count = 0
        listOfUsers.removeAll()
        if let uGroupList = group["groupList"] as? [String] {
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
                                self.counter++
                                if self.count == self.counter {
                                    dispatch_async(dispatch_get_main_queue()) {
                                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "gotUserList", object: nil))
                                    }
                                }
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
    
    func queryUserByUserName(username :String) {
        let query = PFUser.query()
        query!.whereKey("username", equalTo: username)
        query!.findObjectsInBackgroundWithBlock { (users, error) -> Void in
            if error == nil {
                if let user = users![0] as? PFUser {
                    self.userByUsername = user
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "gotUserByUserName", object: nil))
                    }
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "noUsernamePopUpErrorMessage", object: nil))
                }
            }
        }
        
    }
    
}
