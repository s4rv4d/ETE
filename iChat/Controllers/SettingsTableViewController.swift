//
//  SettingsTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/19/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //navigation bar big titles
        navigationController?.navigationBar.prefersLargeTitles = true

    }
    
    
    //MARK:IBActions
    @IBAction func logoutButtonPressed(_ sender: UIButton) {
        FUser.logOutCurrentUser { (success) in
            if success{
                //show login page now after logout
                self.ShowloginPage()
            }
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }
    
    //MARK:Functions
    
    func ShowloginPage(){
        
        //initialize storyboard
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginPage")
        
        self.present(mainView, animated: true, completion: nil)
    }
    

}
