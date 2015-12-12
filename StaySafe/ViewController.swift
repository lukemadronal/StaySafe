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
    var myCurrentGroups = [PFObject]()
    
    //counters
    var groupsCount = Int32()
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
        if segue.identifier == "multipleGroupsSegue" {
            let multipleGroupsViewController = segue.destinationViewController as! MutlipleGroupsViewController
            multipleGroupsViewController.myGroupsArray = myCurrentGroups
        }
    }
    //MARK: - Interactivity Methods
    
    @IBAction func headingOutButtonPressed(sender: UIButton) {
        headingOutPressed = true
        if PFUser.currentUser() != nil {
           print("groups count is \(groupsCount)")
            if groupsCount > 0 {
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
            performSegueWithIdentifier("groupsImInSegue", sender: nil)
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
    
    func countMyGroups() {
        let query = PFQuery(className:"Groups")
        if let currentUser = PFUser.currentUser() {
            query.whereKey("groupLeaderUsername", equalTo:currentUser.username!)
            query.countObjectsInBackgroundWithBlock({ (count, error) -> Void in
                self.groupsCount = count
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "receivedDataFromParseVC", object: nil))
                }
            })
        } else {
            headingOutButton.setTitle("Heading Out?", forState: .Normal)
        }
    }
    
    func dataFromParseRecievedVC() {
        print("VWA count is \(groupsCount)")
        if groupsCount > 0 {
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
    
    //MARK: - Life Cycle Methods
    
    func dataFromParseRecieved() {
        myCurrentGroups = dataManager.myGroupsArray
        coreLoc.sendGroupsToCoreLoc(myCurrentGroups)
        for group in myCurrentGroups {
            dataManager.queryGroupListToFriendList(group)
        }
    }
    
    func sendUserList() {
        coreLoc.sendUsersToCoreLoc(dataManager.listOfUsers)
        //print("VC final user list is \(dataManager.listOfUsers)")
    }
    
    func updateCount() {
        myCurrentGroups.removeAll()
        groupsCount = 0
        countMyGroups()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PFUser.logOut()
        headingOutPressed = false
        loginButton.title = "LogIn"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecievedVC", name: "receivedDataFromParseVC", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecieved", name: "receivedDataFromParse", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sendUserList", name: "gotUserList", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateCount", name: "updatedGroup", object: nil)
        let color1 = UIColor(red: 255/255, green: 106/255, blue: 99/255, alpha: 0.85)
        let color2 = UIColor(red: 255/255, green: 90/255, blue: 114/255, alpha: 0.85)
        let color3 = UIColor(red: 222/255, green: 98/255, blue: 135/255, alpha: 0.85)
        headingOutButton.backgroundColor = color1
        groupsImInButton.backgroundColor = color2
        startStopLocMonitoringButton.backgroundColor = color3
        alarmsButton.backgroundColor = color1
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        myCurrentGroups.removeAll()
        groupsCount = 0
        countMyGroups()
        dataManager.findMyGroups()
        print("vwa vwa vwa")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

