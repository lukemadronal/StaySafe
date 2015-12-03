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
    
    func queryGroupListToFriendList(group: PFObject) -> [PFUser] {
        if let uGroupList = group["groupList"] as? [String] {
            print("unwrapped the group called \(group["groupName"])")
            for member in uGroupList {
                do {
                    let user = try PFQuery.getUserObjectWithId(member)
                    if !listOfUsers.contains(user) {
                        print("user \(user.username!)")
                        listOfUsers.append(user)
                    }
                } catch {
                    print("error getting object ID's from groupList")
                }
                
            }
        }
        return listOfUsers
    }
    
}
