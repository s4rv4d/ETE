//
//  UsersTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/21/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class UsersTableViewController: UITableViewController {
    
    //MARK:IBOutlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var filterSegmentedController: UISegmentedControl!
    
    //MARK:Variables
    var allUsers = [FUser]()
    var filteredUsers = [FUser]()
    var allUsersGroupped = NSDictionary() as! [String:[FUser]]
    var sectionTiltes = [String]()
    
    //create a UISearchController
    let searchController = UISearchController(searchResultsController: nil)
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UsersTableViewCell
        return cell
    }

}

//MARK:Extensions

extension UsersTableViewController: UISearchResultsUpdating{
    
    //MARK:Search functions
    func updateSearchResults(for searchController: UISearchController) {
        <#code#>
    }
    
    
}
