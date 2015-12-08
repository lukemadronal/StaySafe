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
    var wait = false
    
    var dataManager = DataManager()
    
    @IBOutlet var multipleGroupsTableView: UITableView!
    
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
        if segue.identifier == "groupToPartyView" {
            let partyViewController = segue.destinationViewController as! PartyViewController
            let indexPath = multipleGroupsTableView.indexPathForSelectedRow!
            let groupToPass = myGroupsArray[indexPath.row]
            partyViewController.currentGroup = groupToPass
            multipleGroupsTableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func dataFromParseRecieved() {
        myGroupsArray = dataManager.myGroupsArray
        multipleGroupsTableView.reloadData()
    }
    
    //MARK: - Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecieved", name: "receivedDataFromParse", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        dataManager.findMyGroups()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
