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
        self.title = "Users"
        self.navigationItem.largeTitleDisplayMode = .never
        //load kCITY by default
        LoadUsers(filter: kCITY)
        //to clear out empty tableview cells
        tableView.tableFooterView = UIView()
        
        //to add search controller to the navigation item
        navigationItem.searchController = searchController
        //to set the search updater to the current viewcontroller
        searchController.searchResultsUpdater = self
        //to avoid dismissing background while searching
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        //for searching part its 1 section while for default state its multiple
        if searchController.isActive && searchController.searchBar.text != ""{
            return 1
        }else{
            return allUsersGroupped.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != ""{
            return filteredUsers.count
        }else{
            //finding section title
            print("section titles are: ",self.sectionTiltes)
            let sectionTitle = self.sectionTiltes[section]
            //user for given section title
            let users = self.allUsersGroupped[sectionTitle]
            return users!.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UsersTableViewCell
        //to create a FUser variable
        var user:FUser
        //to checking if searching or not
        if searchController.isActive && searchController.searchBar.text != ""{
            user = filteredUsers[indexPath.row]
        }else{
            let sectionTitle = self.sectionTiltes[indexPath.section]
            let users = self.allUsersGroupped[sectionTitle]
            print(users!)
            user = users![indexPath.row]
        }
        cell.GenerateCellWith(fuser: user, indexPath: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if searchController.isActive && searchController.searchBar.text != ""{
            return ""
        }else{
            return sectionTiltes[section]
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != ""{
            return nil
        }else{
            return self.sectionTiltes
        }
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        //jumps to section when you tap on it
        return index
    }
    
    //MARK:Functions
    func LoadUsers(filter:String){
        //show progress
        ProgressHUD.show()
        
        //create a query instance
        var query:Query!
        
        //depending on filter we'll create separate queries
        //switch
        switch filter {
        case kCITY:
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        query.getDocuments { (snapshot, error) in
            self.allUsers = []
            self.sectionTiltes = []
            self.allUsersGroupped = [:]
            
            if error != nil{
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
//                ProgressHUD.showError(error!.localizedDescription)
                self.tableView.reloadData()
                return
            }
            
            guard let snapshot = snapshot else{
                ProgressHUD.dismiss()
                return
            }
            
            if !snapshot.isEmpty{
                for userDict in snapshot.documents{
                    let userDictionary = userDict.data() as NSDictionary
                    let fuser = FUser(_dictionary: userDictionary)
                    
                    if fuser.objectId != FUser.currentId(){
                        self.allUsers.append(fuser)
                    }
                }
                
                //split into groups
                self.SplitAllUsersIntoGroups()
                self.tableView.reloadData()
            }
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
    fileprivate func SplitAllUsersIntoGroups(){
        //section title
        var sectionTitle:String = ""
        for i in 0..<self.allUsers.count{
            //access the user
            let currentUser = self.allUsers[i]
            //acces the first character
            let firstCharacter = currentUser.firstname.first!
            //convert character to string
            let firstCharacterToString = String(firstCharacter)
            
            //to check if the section title doesnt exists
            if firstCharacterToString != sectionTitle{
                sectionTitle = firstCharacterToString
                //clear the fuser array for the new section title first
                self.allUsersGroupped[sectionTitle] = []
                self.sectionTiltes.append(sectionTitle)
            }
            //then append to array
            self.allUsersGroupped[firstCharacterToString]!.append(currentUser)
        }
        
    }
    
    //MARK:IBActions
    @IBAction func FilterValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            LoadUsers(filter: kCITY)
            break
        case 1:
            LoadUsers(filter: kCOUNTRY)
            break
        case 2:
            LoadUsers(filter: "")
            break
        default:
            return
        }
    }
    
    

}

//MARK:Extensions

extension UsersTableViewController: UISearchResultsUpdating{
    
    //MARK:Search functions
    func updateSearchResults(for searchController: UISearchController) {
        //insert the searchbar text inside function
        FilterContentForSearch(searchText: searchController.searchBar.text!)
    }
    
    func FilterContentForSearch(searchText:String,scope:String="All"){
        filteredUsers = allUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        
        //reload data after filtered users
        tableView.reloadData()
    }
    
    
}
