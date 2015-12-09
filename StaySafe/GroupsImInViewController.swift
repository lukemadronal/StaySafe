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
        groupsImInTableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func updateGroupsImIn() {
        print("got into selector updateGroups")
        groupsImInList = dataManager.allGroups
        groupsImInTableView.reloadData()
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateGroupsImIn", name: "gotGroupsImIn", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("groups im in VWA")
        dataManager.queryGroupsImIn()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
