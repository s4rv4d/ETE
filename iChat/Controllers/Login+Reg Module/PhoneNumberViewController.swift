//
//  PhoneNumberViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 1/3/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import UIKit
import FirebaseAuth
import ProgressHUD

class PhoneNumberViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var mobileNoTextField: UITextField!
    @IBOutlet weak var veriCodeTextField: UITextField!
    @IBOutlet weak var requestButtonOutlet: UIButton!
    
    
    //MARK: - Variables
    var phoneNumber:String!
    var verificationID:String?
    
    //MARK: - Main
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        veriCodeTextField.isHidden = true
        countryCodeTextField.text = CountryCode().currentCode
    }
    
    //MARK: - IBActions
    @IBAction func VeriTapped(_ sender: UIButton) {
        self.view.endEditing(true)
        //registered
        if verificationID != nil{
            print("hererefer")
            RegisterUser()
            return
        }
        //request code
        if mobileNoTextField.text != "" && countryCodeTextField.text != ""{
            
            let fullNo = countryCodeTextField.text! + mobileNoTextField.text!
            
            PhoneAuthProvider.provider().verifyPhoneNumber(fullNo, uiDelegate: nil) { (_verificationID, error) in
                if error != nil{
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                }else{
                    self.verificationID = _verificationID
                    self.UpdateUI()
                }
            }
        }else{
            ProgressHUD.showError("Phone number is required")
        }
    }
    //MARK: - Helper functions
    func UpdateUI(){
        requestButtonOutlet.setTitle("Submit", for: .normal)
        phoneNumber = countryCodeTextField.text! + mobileNoTextField.text!
        countryCodeTextField.isEnabled = false
        mobileNoTextField.isEnabled = false
        mobileNoTextField.placeholder = mobileNoTextField.text!
        mobileNoTextField.text = ""
        veriCodeTextField.isHidden = false
    }
    
    func RegisterUser(){
        if veriCodeTextField.text != "" && verificationID != nil{
            FUser.registerUserWith(phoneNumber: phoneNumber, verificationCode: veriCodeTextField.text!, verificationId: verificationID) { (error, shouldLogin) in
                if error != nil{
                    ProgressHUD.showError(error!.localizedDescription)
                    return
                }
                
                if shouldLogin{
                    //go to app
                    self.GoToApp()
                }else{
                    //finish reg
                    self.performSegue(withIdentifier: "reg", sender: self)
                }
                
            }
        }else{
            ProgressHUD.showError("Please input the verification code!")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "reg"{
            if let dest = segue.destination as? FinishRegistrationViewController{
                dest.type = "phone"
            }
        }
    }
    
    func GoToApp(){
        self.view.endEditing(true)
        ProgressHUD.dismiss()
        
        //posting a notification
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID:FUser.currentId()])
        
        //initialize a storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainApplication") as! UITabBarController
        //presenting it
        self.present(mainView, animated: true, completion: nil)
        
    }
}
