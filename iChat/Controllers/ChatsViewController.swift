//
//  ChatsViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/23/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

class ChatsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    //MARK:IBActions
    @IBAction func NewMessage(_ sender: UIBarButtonItem) {
        //access the users storyboard using storyboardID and present using navigation push method
        let userViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        self.navigationController?.pushViewController(userViewController, animated: true)
    }
    
}
