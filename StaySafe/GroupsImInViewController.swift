//
//  GroupsImInViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/8/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import Parse
class GroupsImInViewController: UIViewController {
    
    var dataManager = DataManager()
    
    var groupsImInList = [PFObject]()
    var userCannotEdit = true
    
    @IBOutlet var groupsImInTableView : UITableView!
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupsImInList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("groupsImInCell", forIndexPath: indexPath)
        let groupName = groupsImInList[indexPath.row]["groupName"]!
        cell.textLabel!.text = (groupName as! String)
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let partyViewController = segue.destinationViewController as! PartyViewController
        let indexPath = groupsImInTableView.indexPathForSelectedRow!
        let groupToPass = groupsImInList[indexPath.row]
        partyViewController.currentGroup = groupToPass
        if PFUser.currentUser()!.username! == String(groupToPass["groupLeaderUsername"]!) {
            partyViewController.userCannotEdit = false
        } else {
            print("current user is not the leader")
            partyViewController.userCannotEdit = true
        }
        groupsImInTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
//    func updateGroupsImIn() {
//        print("got into selector updateGroups")
//        groupsImInList = dataManager.allGroups
//        groupsImInTableView.reloadData()
//        
//    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("groups im in VWA")
        dataManager.queryGroupsImIn()
       groupsImInTableView.backgroundColor = UIColor(red: 222/255, green: 98/255, blue: 135/255, alpha: 0.85)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
