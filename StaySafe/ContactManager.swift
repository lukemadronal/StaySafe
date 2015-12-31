//
//  ContactManager.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/28/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import Parse

class ContactManager: NSObject {
    
    static let sharedInstance = ContactManager()
    
    func deleteGroup(currentGroup: PFObject, var usersToAddArray: [PFUser]) ->[PFUser] {
        if String(currentGroup["groupLeaderUsername"]!) == PFUser.currentUser()!.username! {
            currentGroup.deleteInBackgroundWithBlock({ (success, error) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "updatedGroup", object: nil))
                    }
                } else {
                    //print("error while deleting group: \(error!.description)")
                }
            })
        } else {
            //print("group name is \(currentGroup!["groupName"]) and \(currentGroup!["groupList"])")
            let newArray = currentGroup["groupList"]
            let indexForUsersArray = newArray.indexOfObject(PFUser.currentUser()!.objectId!)
            newArray.removeObject(PFUser.currentUser()!.objectId!)
            
            currentGroup["groupList"] = newArray
            let newACL = currentGroup.ACL
            newACL!.setReadAccess(false, forUser: PFUser.currentUser()!)
            newACL!.setWriteAccess(false, forUser: PFUser.currentUser()!)
            currentGroup.ACL = newACL!
            currentGroup.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                if success {
                    //print("success saving")
                } else {
                    //print("the " + error!.description)
                }
                
            })
            usersToAddArray.removeAtIndex(indexForUsersArray)
        }
        return usersToAddArray
    }
    
    func addUserToGroup(user:PFUser, usersToAdd: [PFUser], groupName: String) ->PFObject {
        let newGroup = PFObject(className:"Groups")
        newGroup["groupName"] = groupName
        newGroup["groupLeaderUsername"] = user.username!
        var userList = [String]()
        let newACL = PFACL()
        newACL.setReadAccess(true, forUser: user)
        newACL.setWriteAccess(true, forUser: user)
        userList.append(user.objectId!)
        
        
        for userToAdd in usersToAdd {
            newACL.setReadAccess(true, forUser: userToAdd)
            newACL.setWriteAccess(true, forUser: userToAdd)
            userList.append(userToAdd.objectId!)
        }
        newGroup.ACL = newACL
        newGroup["groupList"] = userList
        newGroup.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "updatedGroup", object: nil))
                }
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "successCreatingGroup", object: nil))
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "failureCreatingGroup", object: nil))
                }
            }
        }
        return newGroup
    }
    
    func editGroup(currentGroup: PFObject, groupName: String, alreadyAddedUsers: [PFUser]) {
        var userList = currentGroup["groupList"] as! [String]
        let newACL = currentGroup.ACL
        for user in alreadyAddedUsers {
            print("alreadyaddedusers user name is: \(user.username!))")
            if !user.isEqual(PFUser.currentUser()) {
                newACL!.setReadAccess(true, forUser: user)
                newACL!.setWriteAccess(true, forUser: user)
                if !userList.contains(user.objectId!) {
                    userList.append(user.objectId!)
                }
            }
        }
        currentGroup.ACL = newACL
        currentGroup["groupList"] = userList
        currentGroup["groupName"] = groupName
        currentGroup.saveInBackgroundWithBlock { (success, error) -> Void in
            if success {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "successEditingGroup", object: nil))
                    print("successfully edited group")
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "failureEditingGroup", object: nil))
                }
            }
        }
    }
}
