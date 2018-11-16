
//
//  FinishRegistrationViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/16/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

class FinishRegistrationViewController: UIViewController {
    
    //MARK:IBOutlets
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var surnameTextfield: UITextField!
    @IBOutlet weak var countryTextfield: UITextField!
    @IBOutlet weak var cityTextfield: UITextField!
    @IBOutlet weak var phoneTextfield: UITextField!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    //MARK:Varibles
    var email:String!
    var password:String!
    var avatarImage:UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        //just to test
        print("email: ",email!)
        print("password: ",password!)
    }

    //MARK:IBActions
    @IBAction func CancelButtonPressed(_ sender: Any) {
    }
    
    @IBAction func DoneButtonPressed(_ sender: Any) {
    }
    
    

}
