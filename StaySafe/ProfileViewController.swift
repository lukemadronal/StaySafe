//
//  ProfileViewController.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/10/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit
import Parse
class ProfileViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //Story Board Items
    @IBOutlet var view1: UIView!
    @IBOutlet var view2: UIView!
    @IBOutlet var view3: UIView!
    @IBOutlet var view4: UIView!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var phoneTextField: UITextField!
    @IBOutlet var selectedImageView:UIImageView!
    
    //Constants
    var keyboardHeight = CGFloat()
    
    //State Variables
    var usernameShouldAdjust = false
    var phoneShouldAdjust = false
    var emailShouldAdjust = false
    var nameShouldAdjust = false
    var currentlyTextField = UITextField()

    //MARK: - Interactivity Methods
    @IBAction func saveBarButtonPressed(sender: UIBarButtonItem) {
        if let currentUser = PFUser.currentUser() {
          currentUser["email"] = emailTextField.text
            currentUser["phoneNumber"] = phoneTextField.text
            currentUser["username"] = usernameTextField.text
            currentUser["name"] = nameTextField.text
            
            let imageData = UIImageJPEGRepresentation(selectedImageView.image!, 1.0)
            let imageFile = PFFile(name:"\(nameTextField.text!)ProfilePicture.png", data:imageData!)
            currentUser["imageName"] = "\(nameTextField.text!)Picture"
            currentUser["imageFile"] = imageFile
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
  //MARK - Keyboard Dismissing Methods
    func textFieldDidBeginEditing(textField: UITextField) {
        currentlyTextField = textField
        self.view.frame.origin.y = 0
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
        self.view.frame.origin.y = 0
    }

    func keyboardWillShow(notification: NSNotification) {
        keyboardHeight = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue().height
        self.view.frame.origin.y -= (currentlyTextField.superview!.frame.origin.y - keyboardHeight*1.4)
    }
    
    //MARK: - Image Capture/Save Methods
    
    @IBAction func galleryButtonTapped(sender : UIBarButtonItem){
        print("Gallery Button Pressed")
        let ipc = UIImagePickerController()
        ipc.delegate = self
        ipc.sourceType = .SavedPhotosAlbum
        presentViewController(ipc, animated: true, completion: nil)
    }
    
    @IBAction func cameraButtonTapped(sender : UIBarButtonItem){
        print("Camera Button Pressed")
        let ipc = UIImagePickerController()
        ipc.delegate = self
        ipc.sourceType = .Camera
        presentViewController(ipc, animated: true, completion: nil)
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            print("got into image picker and unwrapped image")
            selectedImageView.contentMode = .ScaleAspectFit
            selectedImageView.image = pickedImage
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
        let color1 = UIColor(red: 255/255, green: 106/255, blue: 99/255, alpha: 0.85)
        let color2 = UIColor(red: 255/255, green: 90/255, blue: 114/255, alpha: 0.85)
        let color3 = UIColor(red: 222/255, green: 98/255, blue: 135/255, alpha: 0.85)
        view1.backgroundColor = color1
        view2.backgroundColor = color2
        view3.backgroundColor = color3
        view4.backgroundColor = color1
        if let profPic = PFUser.currentUser()!["imageFile"] as? PFFile {
            profPic.getDataInBackgroundWithBlock({ (imageData, error) -> Void in
                if error == nil {
                    if let image = UIImage(data:(imageData)!){
                        self.selectedImageView.image = image
                        self.selectedImageView.contentMode = .ScaleAspectFit
                    }
                } else {
                    print("error in getting prof pic:\(error!.description)")
                }
            })
        }
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
