//
//  MutlipleGroupsViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/1/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import ParseUI
import Parse

class MutlipleGroupsViewController: UIViewController {
    
    var myGroupsArray = [PFObject]()
    var listOfUsers = [PFUser]()
    //var userNameArray = [String]()
    @IBOutlet var multipleGroupsTableView: UITableView!
    
    //MARK: - Parse Query Method
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
    
    func queryGroupListToFriendList(group: PFObject) {
        if let uGroupList = group["groupList"] as? [String] {
            print("unwrapped the group called \(group["groupName"])")
            for member in uGroupList {
                do {
                    let user = try PFQuery.getUserObjectWithId(member)
//                    if (!userNameArray.contains(user.username!)) {
//                        userNameArray.append(user.username!)
//                    }
                    if !listOfUsers.contains(user) {
                        print("user \(user.username!)")
                        listOfUsers.append(user)
                    }
                } catch {
                    print("error getting object ID's from groupList")
                }
                
            }
        }
        
    }
    
    //MARK: - Table View Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myGroupsArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("multipleGroupCell", forIndexPath: indexPath)
        let groupName = myGroupsArray[indexPath.row]["groupName"]!
        cell.textLabel!.text = (groupName as! String)
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let partyViewController = segue.destinationViewController as! PartyViewController
        let indexPath = multipleGroupsTableView.indexPathForSelectedRow!
        let groupToPass = myGroupsArray[indexPath.row]
        partyViewController.currentGroup = groupToPass
        partyViewController.usersToAddArray = listOfUsers
        //partyViewController.friendToAddArray = userNameArray
        multipleGroupsTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    //MARK: - Life Cycle Methods
    
    func dataFromParseRecieved() {
        for group in myGroupsArray {
            queryGroupListToFriendList(group)
        }
        multipleGroupsTableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecieved", name: "receivedDataFromParse", object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        listOfUsers.removeAll()
        findMyGroups()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
