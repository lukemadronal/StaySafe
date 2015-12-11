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

class PartyViewController: UIViewController,CNContactPickerDelegate, CNContactViewControllerDelegate {
    
    @IBOutlet var enterUsernameTextField :UITextField!
    @IBOutlet var friendsToAddTableView: UITableView!
    @IBOutlet var groupNameTextField :UITextField!
    
    var contactStore = CNContactStore()
    var dataManager = DataManager()
    
    var usersToAddArray = [PFUser]()
    var alreadyAddedUsers = [PFUser]()
    var currentGroup : PFObject?
    
    var noUserFound = false
    var editingGroup = false
    var addingCurrentUser = false
    
    //MARK: - Contact Methods
    func requestAccessToContactType(type: CNEntityType) {
        contactStore.requestAccessForEntityType(type) { (accessGranted: Bool, error: NSError?) -> Void in
            if accessGranted {
                print("granted")
            } else {
                print("not granted")
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
        print("done with " + contact!.familyName)
    }
    
    func presentContactMatchingName(name: String) {
        let predicate = CNContact.predicateForContactsMatchingName(name)
        let keysToFetch = [CNContactViewController.descriptorForRequiredKeys()]
        do {
            let contacts = try contactStore.unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
            if let firstContact = contacts.first {
                print("Contact: " + firstContact.familyName)
                displayContact(firstContact)
            }
        } catch {
            print("error")
        }
    }
    
    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        var contactEmail = ""
        if contact.emailAddresses.count > 0 {
            contactEmail = contact.emailAddresses[0].value as! String
        } else {
            print("no email listed")
            contactEmail = " "
        }
        
        if let selectedUser = queryContactByEmail(contactEmail) {
            if !(selectedUser.objectId! == PFUser.currentUser()!.objectId) {
                if editingGroup {
                    print("added \(selectedUser.username) to already added users")
                    alreadyAddedUsers.append(selectedUser)
                } else {
                    usersToAddArray.append(selectedUser)
                    friendsToAddTableView.reloadData()
                }
            } else {
                addingCurrentUser = true
            }
        } else {
            print("email for user not found, looking for phone number")
            var phoneNumbers = [String]()
            if contact.phoneNumbers.count > 0 {
                for number in contact.phoneNumbers {
                    phoneNumbers.append(String((number.value as? CNPhoneNumber)!.valueForKey("digits")!))
                }
                print("phone numbers is \(phoneNumbers)")
            } else {
                print("no phone numbers found")
            }
            print("query phone numbas is being called")
            dataManager.queryUserBasedOnPhoneNumber(phoneNumbers)
            noUserFound = true
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
    
    func editGroup() {
        var userList = currentGroup!["groupList"] as! [String]
        let newACL = currentGroup!.ACL
        for user in alreadyAddedUsers {
            print("alreadyaddedusers user name is: \(user.username))")
            if !user.isEqual(PFUser.currentUser()) {
                newACL!.setReadAccess(true, forUser: user)
                newACL!.setWriteAccess(false, forUser: user)
                if !userList.contains(user.objectId!) {
                    userList.append(user.objectId!)
                }
            }
        }
        currentGroup!.ACL = newACL
        currentGroup!["groupList"] = userList
        currentGroup!["groupName"] = groupNameTextField!.text!
        currentGroup!.saveInBackgroundWithBlock { (success, error) -> Void in
            if success {
                let alert = UIAlertController(title: "Success!", message: "Your group has been successfully edited :)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                    self.navigationController!.popToRootViewControllerAnimated(true)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    func addUserToGroup(user:PFUser, usersToAdd: [PFUser], groupName: String) {
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
            newACL.setWriteAccess(false, forUser: userToAdd)
            userList.append(userToAdd.objectId!)
        }
        newGroup.ACL = newACL
        newGroup["groupList"] = userList
        newGroup.saveInBackgroundWithBlock {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                print("Success Saving")
                // The object has been saved.
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "updatedGroup", object: nil))
                }
                let alert = UIAlertController(title: "Success!", message: "Your group has been successfully created :)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action: UIAlertAction!) in
                    self.navigationController!.popToRootViewControllerAnimated(true)
                }))
                
                
                self.presentViewController(alert, animated: true, completion: nil)
                
            } else {
                let alert = UIAlertController(title: "Error!", message: "There was a problem with your group, please try again later! :(", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                // There was a problem, check error.description
            }
        }
        currentGroup = newGroup
    }
    
    //MARK: - Interactivity Methods
    
    @IBAction func addAllButtonPressed(sender: UIButton) {
        if groupNameTextField.text != ""  {
            if editingGroup {
                editGroup()
            } else {
                addUserToGroup(PFUser.currentUser()!, usersToAdd: usersToAddArray, groupName: groupNameTextField.text!)
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
            uCurrentGroup.deleteInBackgroundWithBlock({ (success, error) -> Void in
                if success {
                    dispatch_async(dispatch_get_main_queue()) {
                        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "updatedGroup", object: nil))
                    }
                } else {
                    print("error while deleting group: \(error!.description)")
                }
                
            })
            self.navigationController!.popToRootViewControllerAnimated(true)
        } else {
            print("you need to have created a group to delete one")
        }
    }
    //MARK: - TableView Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersToAddArray.count
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("friendsToAddCell", forIndexPath: indexPath)
        cell.textLabel!.text = usersToAddArray[indexPath.row].username!
        return cell
    }
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
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
                    print("success saving")
                } else {
                    print("the " + error!.description)
                }
                
            })
            usersToAddArray.removeAtIndex(indexPath.row)
        }
        friendsToAddTableView.reloadData()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let mapViewController = segue.destinationViewController as! MapViewController
        let indexPath = friendsToAddTableView.indexPathForSelectedRow!
        let userToPass = usersToAddArray[indexPath.row]
        mapViewController.currentUser = userToPass
    }
    
    //MARK: - Life Cycle Methods
    func sendUsersList() {
        usersToAddArray = dataManager.listOfUsers
        //alreadyAddedUsers = dataManager.listOfUsers
        friendsToAddTableView.reloadData()
    }
    
    func addUserByUsername() {
        if editingGroup {
            print("added \(dataManager.userByUsername) to already added users")
            alreadyAddedUsers.append(dataManager.userByUsername)
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
    
    func gotUserFromPhoneNumber(){
        if let selectedUser =  dataManager.userByPhoneNumber{
            if !(selectedUser.objectId! == PFUser.currentUser()!.objectId) {
                if editingGroup {
                    print("added \(selectedUser.username) to already added users")
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sendUsersList", name: "gotUserList", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "addUserByUsername", name: "gotUserByUserName", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "noUserNameRecieved", name: "noUsernamePopUpErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "noUserNameFromPhoneNumberRecieved", name: "noPhoneNumberPopUpErrorMessage", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "gotUserFromPhoneNumber", name: "gotUserByPhoneNumber", object: nil)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let uCurrentGroup = currentGroup {
            print("unwrapped current group which means editing")
            editingGroup = true
            dataManager.queryGroupListToFriendList(uCurrentGroup)
            groupNameTextField.text = String(uCurrentGroup["groupName"])
        } else {
            print("not editing group")
            editingGroup = false
        }
        if noUserFound {
            let alert = UIAlertController(title: "No User", message: "No user matches your query. Try again :)", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            noUserFound = false
        }
        if addingCurrentUser {
            let alert = UIAlertController(title: "That's you!", message: "You're already in your own group!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
