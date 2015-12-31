//
//  PartyViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 11/30/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import ParseUI
import Parse
import Contacts
import ContactsUI

class PartyViewController: UIViewController,CNContactPickerDelegate, CNContactViewControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet var enterUsernameTextField :UITextField!
    @IBOutlet var friendsToAddTableView: UITableView!
    @IBOutlet var groupNameTextField :UITextField!
    @IBOutlet var removeBarButtonItem: UIBarButtonItem!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var searchUsernameButton :UIButton!
    @IBOutlet var searchContactsButton :UIButton!
    @IBOutlet var friendsToAddTopConstraint: NSLayoutConstraint!
    @IBOutlet var friendsToAddBottomConstraint: NSLayoutConstraint!
    
    var contactStore = CNContactStore()
    var dataManager = DataManager()
    var contactManager = ContactManager()
    
    var usersToAddArray = [PFUser]()
    var alreadyAddedUsers = [PFUser]()
    var currentGroup : PFObject?
    
    var noUserFound = false
    var editingGroup = false
    var addingCurrentUser = false
    var currentUserLeadingGroup = false
    var userCannotEdit = false
    
    //MARK: - Contact Methods
    func requestAccessToContactType(type: CNEntityType) {
        contactStore.requestAccessForEntityType(type) { (accessGranted: Bool, error: NSError?) -> Void in
            if accessGranted {
                //print("granted")
            } else {
                //print("not granted")
            }
        }
    }
    
    func checkContactAuthorizationStatus(type: CNEntityType) {
        let status = CNContactStore.authorizationStatusForEntityType(type)
        switch status {
        case CNAuthorizationStatus.NotDetermined:
            print("not determined")
        case CNAuthorizationStatus.Authorized:
            print("Authorized")
        case CNAuthorizationStatus.Restricted, CNAuthorizationStatus.Denied:
            print("Restricted/Denied")
        }
    }
    
    //MARK: - Contact Helper Methods
    func displayContact(contact: CNContact) {
        let contactVC = CNContactViewController(forContact: contact)
        contactVC.delegate = self
        contactVC.contactStore = contactStore
        navigationController!.pushViewController(contactVC, animated: true)
    }
    
    func contactViewController(viewController: CNContactViewController, didCompleteWithContact contact: CNContact?) {
        //print("done with " + contact!.familyName)
    }
    
    func presentContactMatchingName(name: String) {
        let predicate = CNContact.predicateForContactsMatchingName(name)
        let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]
        do {
            let contacts = try contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
            if let firstContact = contacts.first {
                //print("Contact: " + firstContact.familyName)
                displayContact(firstContact)
            }
        } catch {
            //print("error")
        }
    }
    
    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        var contactEmail = ""
        if contact.emailAddresses.count > 0 {
            contactEmail = contact.emailAddresses[0].value as! String
        } else {
            //print("no email listed")
            contactEmail = " "
        }
        if let selectedUser = queryContactByEmail(contactEmail) {
            if !(selectedUser.objectId! == PFUser.currentUser()!.objectId) {
                if editingGroup {
                    //print("added \(selectedUser.username) to already added users")
                    alreadyAddedUsers.append(selectedUser)
                } else {
                    usersToAddArray.append(selectedUser)
                    friendsToAddTableView.reloadData()
                }
            } else {
                addingCurrentUser = true
            }
        } else {
            //print("email for user not found, looking for phone number")
            var phoneNumbers = [String]()
            if contact.phoneNumbers.count > 0 {
                for number in contact.phoneNumbers {
                    phoneNumbers.append(String((number.value as? CNPhoneNumber)!.valueForKey("digits")!))
                }
                //print("phone numbers is \(phoneNumbers)")
            } else {
                //print("no phone numbers found")
                noUserFound = true
            }
            //print("query phone numbas is being called")
            dataManager.queryUserBasedOnPhoneNumber(phoneNumbers)
        }
    }
    
    func queryContactByEmail(email: String) -> PFUser? {
        let query = PFUser.query()!
        query.limit = 1
        query.whereKey("email", equalTo:email)
        do {
            let contacts = try query.findObjects()
            if contacts.count > 0 {
                return (contacts[0] as! PFUser)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    //MARK: - Interactivity Methods
    
    @IBAction func addAllButtonPressed(sender: UIBarButtonItem) {
        if groupNameTextField.text != ""  {
            if editingGroup {
                contactManager.editGroup(currentGroup!, groupName: groupNameTextField.text!, alreadyAddedUsers: alreadyAddedUsers)
            } else {
                currentGroup = contactManager.addUserToGroup(PFUser.currentUser()!, usersToAdd: usersToAddArray, groupName: groupNameTextField.text!)
            }
            usersToAddArray.removeAll()
            currentGroup = nil
        } else {
            let alert = UIAlertController(title: "Enter Group Name!", message: "You need to pick a group name to create a group", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func searchForFriendByUsername(sender: UIButton) {
        let username = enterUsernameTextField!.text!
        dataManager.queryUserByUserName(username)
    }
    
    @IBAction func addFriendButtonPressed(sender: UIButton) {
        let contactListVC = CNContactPickerViewController()
        contactListVC.delegate = self
        presentViewController(contactListVC, animated: true, completion: nil)
    }
    
    @IBAction func deleteBarButtonPressed(sender: UIBarButtonItem) {
        if let uCurrentGroup = currentGroup {
            usersToAddArray = contactManager.deleteGroup(uCurrentGroup, usersToAddArray: usersToAddArray)
            self.navigationController!.popToRootViewControllerAnimated(true)
        }
    }
    //MARK: - TableView Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersToAddArray.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UserTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friendsToAddCell", forIndexPath: indexPath) as! UserTableViewCell
        cell.nameLabel.text = usersToAddArray[indexPath.row].username!
        
        if let profPic = usersToAddArray[indexPath.row]["imageFile"] as? PFFile {
            profPic.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                if error == nil {
                    if let image = UIImage(data:(imageData)!){
                        cell.profPicThumbnail.image = image
                    }
                } else {
                    //print("error in getting prof pic:\(error!.description)")
                }
            })
        }
        
        return cell
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        print("currentUserLeadingGroup is \(currentUserLeadingGroup)")
        if currentUserLeadingGroup {
            if (editingStyle == .Delete) {
                print("group name is \(currentGroup!["groupName"]) and \(currentGroup!["groupList"])")
                
                let userToDelete = usersToAddArray[indexPath.row]
                let newArray = currentGroup!["groupList"]
                newArray.removeObject(userToDelete.objectId!)
                currentGroup!["groupList"] = newArray
                
                let newACL = currentGroup!.ACL
                newACL!.setReadAccess(false, forUser: userToDelete)
                newACL!.setWriteAccess(false, forUser: userToDelete)
                currentGroup!.ACL = newACL!
                
                currentGroup!.saveInBackgroundWithBlock({ (success: Bool, error: NSError?) -> Void in
                    if success {
                        //print("success saving")
                    } else {
                        //print("the " + error!.description)
                    }
                    
                })
                usersToAddArray.removeAtIndex(indexPath.row)
            }
            friendsToAddTableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let mapViewController = segue.destinationViewController as! MapViewController
        let indexPath = friendsToAddTableView.indexPathForSelectedRow!
        let userToPass = usersToAddArray[indexPath.row]
        mapViewController.currentUser = userToPass
    }
    
    //MARK: - Notification Selector Methods
    
    func sendUsersList() {
        usersToAddArray = dataManager.listOfUsers
        //alreadyAddedUsers = dataManager.listOfUsers
        friendsToAddTableView.reloadData()
    }
    
    func addUserByUsername() {
        if editingGroup {
            print("added \(dataManager.userByUsername) to already added users")
            alreadyAddedUsers.append(dataManager.userByUsername)
            usersToAddArray.append(dataManager.userByUsername)
        } else {
            usersToAddArray.append(dataManager.userByUsername)
        }
        friendsToAddTableView.reloadData()
        let alert = UIAlertController(title: "Success!", message: "User found! :)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func noUserNameRecieved() {
        let alert = UIAlertController(title: "Error!", message: "There was a problem with your group, please try again later! :(", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func noUserNameFromPhoneNumberRecieved() {
        let alert = UIAlertController(title: "No user found!", message: "There is no user in our data base matching that contact info :(", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func noUserMatchesQuery() {
        let alert = UIAlertController(title: "No User", message: "No user matches your query. Try again :)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
        noUserFound = false
    }
    
    func gotUserFromPhoneNumber(){
        if let selectedUser =  dataManager.userByPhoneNumber{
            if !(selectedUser.objectId! == PFUser.currentUser()!.objectId) {
                if editingGroup {
                    //print("added \(selectedUser.username) to already added users")
                    alreadyAddedUsers.append(selectedUser)
                } else {
                    usersToAddArray.append(selectedUser)
                    friendsToAddTableView.reloadData()
                }
            } else {
                addingCurrentUser = true
            }
        } else {
            noUserFound = true
        }
        let alert = UIAlertController(title: "Success!", message: "User found! :)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func groupSuccessfullyCreatedNotification() {
        let alert = UIAlertController(title: "Success!", message: "Your group has been successfully created :)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
            self.navigationController!.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func groupFailureCreatedNotification() {
        let alert = UIAlertController(title: "Error!", message: "There was a problem with your group, please try again later! :(", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    func groupSuccessfullyEditedNotification() {
        let alert = UIAlertController(title: "Success!", message: "Your group has been successfully edited :)", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
            self.navigationController!.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func groupFailureEditedNotification() {
        let alert = UIAlertController(title: "Error!", message: "Failed to edit your group :(", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
            self.navigationController!.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: - Life Cycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupSuccessfullyEditedNotification", name: "successEditingGroup", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupFailureEditedNotification", name: "failureCreatingGroup", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupSuccessfullyCreatedNotification", name: "successCreatingGroup", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "groupFailureCreatedNotification", name: "failureCreatingGroup", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sendUsersList", name: "gotUserList", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addUserByUsername", name: "gotUserByUserName", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "noUserNameRecieved", name: "noUsernamePopUpErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "noUserNameFromPhoneNumberRecieved", name: "noPhoneNumberPopUpErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gotUserFromPhoneNumber", name: "gotUserByPhoneNumber", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "noUserMatchesQuery", name: "noUserMatchesQuery", object: nil)
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        friendsToAddTableView.backgroundColor = UIColor(red: 77/255, green: 174/255, blue: 255/255, alpha: 0.85)//        view.backgroundColor = UIColor(red: 255/255, green: 106/255, blue: 99/255, alpha: 0.5)
//        backgroundView.backgroundColor = UIColor(red: 255/255, green: 106/255, blue: 99/255, alpha: 0.5)
        
        if let uCurrentGroup = currentGroup {
            print("unwrapped current group which means editing")
            editingGroup = true
            if usersToAddArray.count == 0 {
                dataManager.queryGroupListToFriendList(uCurrentGroup)
            }
            groupNameTextField.text = String(uCurrentGroup["groupName"])
            if PFUser.currentUser()!.username == String(uCurrentGroup["groupName"]) {
                currentUserLeadingGroup = true
            } else {
                currentUserLeadingGroup = false
            }
        } else {
            ////print("not editing group")
            editingGroup = false
        }
        if noUserFound {
            let alert = UIAlertController(title: "No User", message: "No user matches your query. Try again :)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            noUserFound = false
        }
        if addingCurrentUser {
            let alert = UIAlertController(title: "That's you!", message: "You're already in your own group!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        if userCannotEdit {
            friendsToAddTopConstraint.constant = -backgroundView.frame.height - navigationController!.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.size.height
            searchContactsButton.hidden = true
            searchUsernameButton.hidden = true
            groupNameTextField.hidden = true
            enterUsernameTextField.hidden = true
            backgroundView.hidden = true
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
