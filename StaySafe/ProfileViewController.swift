//
//  ProfileViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/10/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import Parse
class ProfileViewController: UIViewController {
    
    @IBOutlet var view1: UIView!
    @IBOutlet var view2: UIView!
    @IBOutlet var view3: UIView!
    @IBOutlet var view4: UIView!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var phoneTextField: UITextField!

    //MARK: - Interactivity Methods
    @IBAction func saveBarButtonPressed(sender: UIBarButtonItem) {
        if let currentUser = PFUser.currentUser() {
          currentUser["email"] = emailTextField.text
            currentUser["phoneNumber"] = phoneTextField.text
            currentUser["username"] = usernameTextField.text
            currentUser["name"] = nameTextField.text
            currentUser.saveInBackgroundWithBlock { (success, error) -> Void in
                if success {
                    let alert = UIAlertController(title: "Success!", message: "Your profile has been successfully edited :)", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                        self.navigationController!.popToRootViewControllerAnimated(true)
                    }))
                    alert.addAction(UIAlertAction(title: "Continue editing", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }

    }
    
    
    //MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let color1 = UIColor(red: 255/255, green: 106/255, blue: 99/255, alpha: 0.85)
        let color2 = UIColor(red: 255/255, green: 90/255, blue: 114/255, alpha: 0.85)
        let color3 = UIColor(red: 222/255, green: 98/255, blue: 135/255, alpha: 0.85)
        view1.backgroundColor = color1
        view2.backgroundColor = color2
        view3.backgroundColor = color3
        view4.backgroundColor = color1
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let currentUser = PFUser.currentUser() {
            if let email = currentUser["email"] as? String {
                emailTextField.text = email
            }
            if let phone = currentUser["phoneNumber"] as? String {
                phoneTextField.text = phone
            }
            if let username = currentUser["username"] as? String {
                usernameTextField.text = username
            }
            if let name = currentUser["name"] as? String {
                nameTextField.text = name
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
