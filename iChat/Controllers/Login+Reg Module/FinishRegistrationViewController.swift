
//
//  FinishRegistrationViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/16/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseFirestore
import ImagePicker

class FinishRegistrationViewController: UIViewController {
    
    //MARK:IBOutlets
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var surnameTextfield: UITextField!
    @IBOutlet weak var countryTextfield: UITextField!
    @IBOutlet weak var cityTextfield: UITextField!
    @IBOutlet weak var phoneTextfield: UITextField!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var imgViewTap: UITapGestureRecognizer!
    
    
    //MARK:Varibles
    var email:String!
    var password:String!
    var avatarImage:UIImage?
    var type:String = ""
    let imgPickerController = ImagePickerController()

    override func viewDidLoad() {
        super.viewDidLoad()
        //just to test
//        print("email: ",email!)
//        print("password: ",password!)
        
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(imgViewTap)
    }

    //MARK:IBActions
    @IBAction func AvatarTapped(_ sender: UITapGestureRecognizer) {
        
        imgPickerController.delegate = self
        imgPickerController.imageLimit = 1
        
        //dismiss keyboard
        dismissKeyboard()
        present(imgPickerController, animated: true, completion: nil)
    }
    
    @IBAction func CancelButtonPressed(_ sender: Any) {
        
        //dismiss keyboard
        self.view.endEditing(true)
        //clear textfields
        clearTextfields()
        //dismiss controller
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func DoneButtonPressed(_ sender: Any) {
        //dismiss keyboard
        self.view.endEditing(true)
        
        //notify user
        ProgressHUD.show("Registering...")
        
        //exeception
        if nameTextfield.text != "" && surnameTextfield.text != "" && countryTextfield.text != "" && cityTextfield.text != "" && phoneTextfield.text != ""{
            
            if type == "phone"{
                self.RegisterUser()
            }else{
                FUser.registerUserWith(email: email!, password: password!, firstName: nameTextfield.text!, lastName: surnameTextfield.text!) { (error) in
                    if error != nil{
                        ProgressHUD.dismiss()
                        ProgressHUD.showError(error!.localizedDescription)
                        return
                    }
                    
                    self.RegisterUser()
                }
            }
        }else{
            ProgressHUD.showError("All fields are required")
        }
    }
    
    //MARK:Helper functions
    func clearTextfields(){
        nameTextfield.text = ""
        surnameTextfield.text = ""
        countryTextfield.text = ""
        cityTextfield.text = ""
        phoneTextfield.text = ""
    }
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    
    func RegisterUser(){
        //full name
        let fullName = nameTextfield.text! + " " + surnameTextfield.text!
        
        //for updating fuser local user object
        var tempDict:Dictionary = [kFIRSTNAME:nameTextfield.text!,
                                     kLASTNAME:surnameTextfield.text!,
                                     kFULLNAME:fullName,
                                     kCOUNTRY:countryTextfield.text!,
                                     kCITY:cityTextfield.text!,
        kPHONE:phoneTextfield.text!] as [String:Any]
        
        //to check if user has selected avatar
        if avatarImage == nil{
            //create image from initials
            imageFromInitials(firstName: nameTextfield.text!, lastName: surnameTextfield.text!) { (avatarInitial) in
                
                //to store to firestore convert avatarInitial to Data
//                let avatarIMG = UIImageJPEGRepresentation(avatarInitial, 0.7)
                let avatarIMG = avatarInitial.jpegData(compressionQuality: 0.7)
                //converting data to string for firestore
                let avatarString = avatarIMG!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                
                tempDict[kAVATAR] = avatarString
                //register
                self.FinishRegistration(withValues: tempDict)
            }
        }else{
//            let avatarData = UIImageJPEGRepresentation(avatarImage!, 0.7)
            let avatarData = avatarImage!.jpegData(compressionQuality: 0.7)
            let avatarString = avatarData!.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDict[kAVATAR] = avatarString
            //register
            self.FinishRegistration(withValues: tempDict)
        }
    }
    
    func FinishRegistration(withValues:[String:Any]){
        //update firestore
        updateCurrentUserInFirestore(withValues: withValues) { (error) in
            if error != nil{
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
            //go to app
            self.GoToApp()
        }
    }
    
    func GoToApp(){
        //clear textfields
        clearTextfields()
        self.view.endEditing(true)
        
        //posting a notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID:FUser.currentId()])
        
        //initialize a storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        
        //presenting it
        self.present(mainView, animated: true, completion: nil)
        
    }

}

//MARK: - Extensions
extension FinishRegistrationViewController: ImagePickerDelegate{
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        //do nothing here, just dismiss
        print("hererere")
        //camera class instance
        let camera = Camera(delegate_: self)
        camera.PresentPhotoLibrary(target: self.imgPickerController, canEdit: true)
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {
        
        if images.count > 0{
            self.avatarImage = images.first!
            self.avatarImageView.image = self.avatarImage!.circleMasked
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {
        //do nothing here, just dismiss
        self.dismiss(animated: true, completion: nil)
    }
    
    
}

extension FinishRegistrationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        self.avatarImage = picture
        self.avatarImageView.image = self.avatarImage!.circleMasked
//        picker.dismiss(animated: true, completion: nil)
        picker.dismiss(animated: true) {
            self.imgPickerController.dismiss(animated: true, completion: nil)
        }
    }
}
