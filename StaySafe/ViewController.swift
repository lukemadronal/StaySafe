//  ViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 11/30/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.

import UIKit
import ParseUI
import Parse

class ViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    //singletons
    var dataManager = DataManager()
    var coreLoc = CoreLoc.sharedInstance
    
    //current users
    var groupsImInList = [PFObject]()
    var tempGroupsImInList = [PFObject]()
    var myCurrentGroups = [PFObject]()
    var listOfUsersByGroup = [String: [PFUser]]()
    
    //counters
    var groupsImInCount = Int32()
    var counter = 0
    
    //state booleans
    var multipleGroupsSegue = true
    var groupsImInPressed = false
    var profilePressed = false
    var headingOutPressed = false
    
    //storyboard variables
    @IBOutlet var loginButton :UIBarButtonItem!
    @IBOutlet var headingOutButton :UIButton!
    @IBOutlet var startStopLocMonitoringButton :UIButton!
    @IBOutlet var groupsImInButton: UIButton!
    @IBOutlet var alarmsButton: UIButton!
    
    //MARK: - User Default Methods
    func setUsernameDefault(username: String) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setObject(username, forKey: "DefaultUsername")
        userDefaults.synchronize()
    }
    
    func getUserNameDefault() ->String {
        if let defaultUserName = NSUserDefaults.standardUserDefaults().stringForKey("DefaultUsername") {
            return defaultUserName
        } else {
            return ""
        }
    }
    
    //MARK: - Login Methods
    
    @IBAction func loginButtonPressed(sender: UIBarButtonItem) {
        if let _ = PFUser.currentUser() {
            PFUser.logOut()
            loginButton.title = "Log In"
            headingOutPressed = false
            headingOutButton.setTitle("Heading Out?", forState: .Normal)
        } else {
            //this needs to be fixed
            let loginController = PFLogInViewController()
            loginController.delegate = self
            let signupController = PFSignUpViewController()
            signupController.delegate = self
            loginController.signUpController = signupController
            loginController.logInView?.usernameField?.text = getUserNameDefault()
            presentViewController(loginController, animated: true, completion: nil)
            
        }
    }
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        dismissViewControllerAnimated(true, completion: nil)
        setUsernameDefault(logInController.logInView!.usernameField!.text!)
        loginButton.title = "Log Out"
        dataManager.countGroupsImIn()
        coreLoc.currentPoint = PFGeoPoint()
        coreLoc.mostRecentPoint = PFGeoPoint()
        if groupsImInPressed {
            performSegueWithIdentifier("groupsImInSegue", sender: nil)
            groupsImInPressed = false
        }
        if profilePressed {
            performSegueWithIdentifier("profileSegue", sender: nil)
            profilePressed = false
        }
    }
    
    func logInViewControllerDidCancelLogIn(logInController: PFLogInViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        dismissViewControllerAnimated(true, completion: nil)
//        if headingOutPressed {
//            print("got into did sign up user heading out pressed was true")
//            performSegueWithIdentifier("headingOutSegue", sender: nil)
//        }
    }
    
    func signUpViewControllerDidCancelSignUp(signUpController: PFSignUpViewController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "groupsImInSegue" {
            let groupsImInViewController = segue.destinationViewController as! GroupsImInViewController
            groupsImInViewController.groupsImInList = groupsImInList
        } else if segue.identifier == "multipleGroupsSegue" {
            let multipleGroupsViewController = segue.destinationViewController as! MutlipleGroupsViewController
            multipleGroupsViewController.myGroupsArray = myCurrentGroups
        }
    }
    //MARK: - Interactivity Methods
    
    @IBAction func headingOutButtonPressed(sender: UIButton) {
        headingOutPressed = true
        if PFUser.currentUser() != nil {
           //print("groups count is \(dataManager.groupsCount)") dataManager.groupsCount
            if dataManager.groupsCount > 0 {
                performSegueWithIdentifier("multipleGroupsSegue", sender: nil)
                multipleGroupsSegue = true
                headingOutPressed = false
            } else {
                performSegueWithIdentifier("headingOutSegue", sender: nil)
                multipleGroupsSegue = false
                headingOutPressed = false
            }
        } else {
            self.loginButtonPressed(loginButton)
        }
    }
    
    @IBAction func groupsImInButtonPressed(sender: UIButton) {
        groupsImInPressed = true
        if PFUser.currentUser() == nil {
            self.loginButtonPressed(loginButton)
        } else {
            if groupsImInCount > 0 {
                performSegueWithIdentifier("groupsImInSegue", sender: nil)
            } else {
                performSegueWithIdentifier("headingOutSegue", sender: nil)
            }
            groupsImInPressed = false
            
        }
    }
    
    @IBAction func profileBarButtonPressed(sender: UIBarButtonItem) {
        profilePressed = true
        if PFUser.currentUser() == nil {
            self.loginButtonPressed(loginButton)
        } else {
            performSegueWithIdentifier("profileSegue", sender: nil)
            profilePressed = false
        }
    }
    
    @IBAction func startStopLocationMonitoring() {
        if startStopLocMonitoringButton.titleLabel!.text == "Done for the night?" {
            coreLoc.stopLocMonotoring()
            startStopLocMonitoringButton.setTitle("Track me!", forState: .Normal)
        } else {
            coreLoc.startLocMonotoring()
            startStopLocMonitoringButton.setTitle("Done for the night?", forState: .Normal)
        }
        
    }
    
    //MARK: - Notifcation Selector Methods
    
    func setHeadingOutButtonTitle() {
        print("in VC my group count is \(dataManager.groupsCount)")
        if dataManager.groupsCount > 0 {
            headingOutButton.setTitle("My Groups", forState: .Normal)
        } else {
            headingOutButton.setTitle("Heading Out?", forState: .Normal)
        }
    }
    
    func dataFromParseRecievedVC() {
        //print("VWA count is \(dataManager.groupsCount)")
        if dataManager.groupsCount > 0 {
            headingOutButton.setTitle("My Groups", forState: .Normal)
            if headingOutPressed {
                headingOutPressed = false
                performSegueWithIdentifier("multipleGroupsSegue", sender: nil)
                multipleGroupsSegue = true
            }
        } else {
            headingOutButton.setTitle("Heading Out?", forState: .Normal)
            if headingOutPressed {
                headingOutPressed = false
                performSegueWithIdentifier("headingOutSegue", sender: nil)
                multipleGroupsSegue = false
            }
        }
    }
    
    func updateGroupsImIn() {
        groupsImInList = dataManager.allGroups
        coreLoc.sendGroupsToCoreLoc(groupsImInList)
        tempGroupsImInList = groupsImInList
        getUsersFromGroupList()
    }
    
    func getUsersFromGroupList() {
        if tempGroupsImInList.count > 0 {
            dataManager.queryGroupListToFriendList(tempGroupsImInList.last!)
        }
    }
    
    func sendUserList() {
        //every time data manager method gets called pass it a new list of people. they should run one after the other not at the same time. keep track of all of the groups you need to grab people from. after data manager sends a user list, delete that group from the list and keep doing it until the array of groups is empty
        if (tempGroupsImInList.count > 0) {
            tempGroupsImInList.removeLast()
            counter++
            dataManager.counter = 1
            listOfUsersByGroup[dataManager.currentGroupName] = dataManager.listOfUsers
            dataManager.listOfUsers.removeAll()
            var finalUserList = [PFUser]()
            //print("counter is \(counter) and groupsImInCount is \(groupsImInList.count)")
            if counter == groupsImInList.count {
                for users in listOfUsersByGroup {
                    finalUserList = users.1 + finalUserList
                }
                coreLoc.sendUsersToCoreLoc(finalUserList)
            } else {
                getUsersFromGroupList()
            }
        }
        //print("in send userList \(dataManager.listOfUsers)")
        //print("VC final user list is \(dataManager.listOfUsers)")
    }
    
    func updateCount() {
        groupsImInList.removeAll()
        dataManager.groupsCount = 0
        dataManager.countMyGroups()
    }
    func getGroupsImInCount() {
       groupsImInCount = dataManager.groupsImInCount
        if groupsImInCount > 0 {
            groupsImInButton.setTitle("Groups I'm in!", forState: .Normal)
        } else {
          groupsImInButton.setTitle("Create a group first!", forState: .Normal)
        }
    }
    
    func dataFromParseRecieved() {
       myCurrentGroups = dataManager.myGroupsArray
    }
    
    //MARK: - Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PFUser.logOut()
        headingOutPressed = false
        loginButton.title = "LogIn"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecieved", name: "receivedDataFromParse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecievedVC", name: "receivedDataFromParseVC", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateGroupsImIn", name: "gotGroupsImIn", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sendUserList", name: "gotUserList", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCount", name: "updatedGroup", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "getGroupsImInCount", name: "countedGroupsImIn", object: nil)
        
        
        //let color1 = UIColor(red: 255/255, green: 106/255, blue: 99/255, alpha: 0.85)
        let color1 = UIColor(red: 77/255, green: 174/255, blue: 255/255, alpha: 1)
        //let color2 = UIColor(red: 77/255, green: 106/255, blue: 99/255, alpha: 0.85)        
        let color2 = UIColor(red: 77/255, green: 128/255, blue: 255/255, alpha: 1)
        
        //let color3 = UIColor(red: 222/255, green: 98/255, blue: 135/255, alpha: 0.85)
        let color3 = UIColor(red: 69/255, green: 91/255, blue: 255/255, alpha: 1)
        headingOutButton.backgroundColor = color1
        groupsImInButton.backgroundColor = color2
        startStopLocMonitoringButton.backgroundColor = color3
        alarmsButton.backgroundColor = color1
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        groupsImInList.removeAll()
        myCurrentGroups.removeAll()
        dataManager.groupsCount = 0
        dataManager.countMyGroups()
        dataManager.queryGroupsImIn()
        dataManager.findMyGroups()
        setHeadingOutButtonTitle()
        //print("vwa vwa vwa")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

