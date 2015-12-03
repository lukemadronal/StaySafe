//  ViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 11/30/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.

import UIKit
import ParseUI
import Parse

class ViewController: UIViewController, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {
    
    var coreLoc = CoreLoc.sharedInstance
    var headingOutPressed = false
    var myCurrentGroups = [PFObject]()
    var groupsCount = Int32()
    
    @IBOutlet var loginButton :UIBarButtonItem!
    @IBOutlet var headingOutButton :UIButton!
    
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
    
    //MARK: - Interactivity Methods
    
    @IBAction func headingOutButtonPressed(sender: UIButton) {
        headingOutPressed = true
        if PFUser.currentUser() != nil {
            if groupsCount > 0 {
                performSegueWithIdentifier("multipleGroupsSegue", sender: nil)
                headingOutPressed = false
            } else {
                performSegueWithIdentifier("headingOutSegue", sender: nil)
                headingOutPressed = false
            }
        } else {
            self.loginButtonPressed(loginButton)
        }
    }
    
    func countMyGroups() {
        let query = PFQuery(className:"Groups")
        if let currentUser = PFUser.currentUser() {
            query.whereKey("groupLeaderUsername", equalTo:currentUser.username!)
            query.countObjectsInBackgroundWithBlock({ (count, error) -> Void in
                self.groupsCount = count
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "receivedDataFromParse", object: nil))
                }
            })
        } else {
            headingOutButton.setTitle("Heading Out?", forState: .Normal)
        }
    }
    
    func dataFromParseRecieved() {
        if groupsCount > 0 {
            headingOutButton.setTitle("My Groups", forState: .Normal)
            if headingOutPressed {
                headingOutPressed = false
                performSegueWithIdentifier("multipleGroupsSegue", sender: nil)
            }
        } else {
            headingOutButton.setTitle("Heading Out?", forState: .Normal)
            if headingOutPressed {
                headingOutPressed = false
                performSegueWithIdentifier("headingOutSegue", sender: nil)
            }
        }
        
    }
    
    //MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        PFUser.logOut()
        headingOutPressed = false
        loginButton.title = "LogIn"
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataFromParseRecieved", name: "receivedDataFromParse", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        countMyGroups()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

