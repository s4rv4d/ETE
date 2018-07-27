//
//  WelcomeViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 7/26/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    //MARK:IBOutlets
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    //MARK:IBActions
    @IBAction func loginButtonPressed(_ sender: UIButton) {
        dismisskeyboard()
    }
    @IBAction func registerButtonPressed(_ sender: UIButton) {
        dismisskeyboard()
    }
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        dismisskeyboard()
    }
    
    //MARK:Helper Functions
    func dismisskeyboard(){
        self.view.endEditing(false)
    }
    func clearKeyboard(){
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }

}
