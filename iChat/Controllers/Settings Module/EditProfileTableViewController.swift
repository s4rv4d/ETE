//
//  EditProfileTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/30/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD

class EditProfileTableViewController: UITableViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var saveButtonOutlet: UIBarButtonItem!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var surnametextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet var pictureTapGesture: UITapGestureRecognizer!
    
    //MARK: - Variables
    var avatarImage:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.largeTitleDisplayMode = .never
        tableView.tableFooterView = UIView()
        
        SetupUI()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 30
//    }

    //MARK: - Functions
    func SetupUI(){
        let currentUser = FUser.currentUser()!
        profileImageView.isUserInteractionEnabled = true
        nameTextField.text = currentUser.firstname
        surnametextField.text = currentUser.lastname
        emailTextField.text = currentUser.email
        
        if currentUser.avatar != ""{
            imageFromData(pictureData: currentUser.avatar) { (image) in
                if image != nil{
                    self.profileImageView.image = image?.circleMasked
                }
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func SaveButtonTapped(_ sender: UIBarButtonItem) {
        
        //validation
        if nameTextField.text != "" && surnametextField.text != "" && emailTextField.text != ""{
            
            ProgressHUD.show("Saving...")
            //block save button
            saveButtonOutlet.isEnabled = false
            
            //edits
            let fullname = nameTextField.text! + " " + surnametextField.text!
            var withValues = [kFIRSTNAME:nameTextField.text!,kLASTNAME:surnametextField.text!,kFULLNAME:fullname]
            
            if avatarImage != nil{
                let avatarData = avatarImage!.jpegData(compressionQuality: 0.7)!
                let avatarString = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                withValues[kAVATAR] = avatarString
            }
            
            //update firebase
            updateCurrentUserInFirestore(withValues: withValues) { (error) in
                if error != nil{
                    DispatchQueue.main.async {
                        ProgressHUD.showError("\(error!.localizedDescription)")
                        print("couldnt update user \(error!.localizedDescription)")
                    }
                    self.saveButtonOutlet.isEnabled = true
                    return
                }
                ProgressHUD.showSuccess("Saved!")
                self.saveButtonOutlet.isEnabled = true
                self.navigationController?.popViewController(animated: true)
            }
        }else{
            ProgressHUD.showError("All fields must be filled!")
        }
        
    }
    
    @IBAction func AvatarTapped(_ sender: UITapGestureRecognizer) {
        print("show image picker")
    }
    
}