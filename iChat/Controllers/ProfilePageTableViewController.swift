//
//  ProfilePageTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/24/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit

class ProfilePageTableViewController: UITableViewController {
    
    //MARK:IBOutlets
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var phoneNo: UILabel!
    @IBOutlet weak var messageButtonOutlet: UIButton!
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var blockUserButtonOutlet: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    
    //MARK:Variables
    var user:FUser?

    override func viewDidLoad() {
        super.viewDidLoad()

        SetupUI()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0{
            //for first header
            return 0
        }
        return 30
    }
    
    //MARK:IBActions
    @IBAction func CallButtonTapped(_ sender: UIButton) {
    }
    @IBAction func MessageButtonPressed(_ sender: UIButton) {
    }
    @IBAction func BlockUserButtonPressed(_ sender: UIButton) {
    }
    
    //MARK:Functions
    func SetupUI(){
        
    }

}
