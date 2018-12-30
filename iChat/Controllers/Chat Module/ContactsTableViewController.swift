//
//  ContactsTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 12/30/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import Contacts
import FirebaseFirestore
import ProgressHUD

class ContactsTableViewController: UITableViewController {

    //MARK: - Variables
    var users: [FUser] = []
    var matchedUsers: [FUser] = []
    var filteredMatchedUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList: [String] = []
    
    var isGroup = false
    var memberIdsOfGroupChat: [String] = []
    var membersOfGroupChat: [FUser] = []
    
    let searchController = UISearchController(searchResultsController: nil)
    
    //lazy means the initialization will only happen when the variable is used
    lazy var contacts: [CNContact] = {
        
        let contactStore = CNContactStore()
        
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey] as [Any]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try     contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }()
    
    //MARK: - Main
    override func viewWillAppear(_ animated: Bool) {
        
        //to remove empty cell lines
        tableView.tableFooterView = UIView()
        LoadUsers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Contacts"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        //button setup
        SetupButtons()
    }
    
    //MARK: - Functions
    func SetupButtons(){
        if isGroup{
            //for group
            let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(self.NextTapped))
            self.navigationItem.rightBarButtonItem = nextButton
            self.navigationItem.rightBarButtonItems!.first?.isEnabled = false
        }else{
            //for one on one chat
            let invButton = UIBarButtonItem(image: UIImage(named: "invite"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.InviteTapped))
            let searchButton = UIBarButtonItem(image: UIImage(named: "nearMe"), style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.SearchTapped))
            //add
            self.navigationItem.rightBarButtonItems = [invButton,searchButton]
        }
    }
    
    @objc func NextTapped(){
        print("next button tapped")
    }
    
    @objc func InviteTapped(){
        let text = "Hey! lets chat on ETE \(kAPPURL)"
        let objectsToShare:[Any] = [text]
        
        //activity vc
        let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.setValue("Lets Chat in ETE", forKey: "subject")
        self.present(activityVC, animated: true, completion: nil)
    }
    
    @objc func SearchTapped(){
        print("show users table view")
    }
    
    func LoadUsers(){
        ProgressHUD.show()
        
        reference(.User).order(by: kFIRSTNAME, descending: false).getDocuments { (snapshot, error) in
            guard let snapshot = snapshot else{
                ProgressHUD.dismiss()
                return
            }
            
            if !snapshot.isEmpty{
                self.matchedUsers = []
                self.users.removeAll()
                
                for userDict in snapshot.documents{
                    let userDic = userDict.data() as NSDictionary
                    let fuser = FUser(_dictionary: userDic)
                    print(fuser)
                    if fuser.objectId != FUser.currentId(){
                        self.users.append(fuser)
                    }
                }
                //dismiss
                ProgressHUD.dismiss()
                self.tableView.reloadData()
            }
                ProgressHUD.dismiss()
                self.compareUsers()
            
        }
    }
    
    //MARK: - TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            print("soososos \(self.allUsersGrouped.count)")
            return self.allUsersGrouped.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredMatchedUsers.count
        } else {
            // find section title
            let sectionTitle = self.sectionTitleList[section]
            
            // find users for given section title
            let users = self.allUsersGrouped[sectionTitle]
            
            // return count for users
            return users!.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as! UsersTableViewCell
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            
            let sectionTitle = self.sectionTitleList[indexPath.section]
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]
            print("users     \(users)")
            user = users![indexPath.row]
        }
        
        cell.delegate = self
        cell.GenerateCellWith(fuser: user, indexPath: indexPath)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return self.sectionTitleList[section]
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return self.sectionTitleList
        }
    }
    
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    
    //MARK: - TableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
    }
    
    func compareUsers() {
        for user in users {
            
            if user.phoneNumber != "" {
                
                let contact = searchForContactUsingPhoneNumber(phoneNumber: user.phoneNumber)
                
                //if we have a match, we add to our array to display them
                if contact.count > 0 {
                    matchedUsers.append(user)
                }
                self.tableView.reloadData()
            }
        }
        //        updateInformationLabel()
        self.splitDataInToSection()
    }
    
    //MARK: - Contacts
    func searchForContactUsingPhoneNumber(phoneNumber: String) -> [CNContact] {
        var result: [CNContact] = []
        //go through all contacts
        for contact in self.contacts {
            if !contact.phoneNumbers.isEmpty {
                //get the digits only of the phone number and replace + with 00
                let phoneNumberToCompareAgainst = updatePhoneNumber(phoneNumber: phoneNumber, replacePlusSign: true)
                //go through every number of each contac
                for phoneNumber in contact.phoneNumbers {
                    
                    let fulMobNumVar  = phoneNumber.value
                    let countryCode = fulMobNumVar.value(forKey: "countryCode") as? String
                    let phoneNumber = fulMobNumVar.value(forKey: "digits") as? String
                    
                    let contactNumber = removeCountryCode(countryCodeLetters: countryCode!, fullPhoneNumber: phoneNumber!)
                    
                    //compare phoneNumber of contact with given user's phone number
                    if contactNumber == phoneNumberToCompareAgainst {
                        result.append(contact)
                    }
                    
                }
            }
        }
        
        return result
    }
    
    func updatePhoneNumber(phoneNumber: String, replacePlusSign: Bool) -> String {
        if replacePlusSign {
            return phoneNumber.replacingOccurrences(of: "+", with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        } else {
            return phoneNumber.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        }
    }
    
    func removeCountryCode(countryCodeLetters: String, fullPhoneNumber: String) -> String {
        let countryCode = CountryCode()
        let countryCodeToRemove = countryCode.codeDictionaryShort[countryCodeLetters.uppercased()]
        //remove + from country code
        let updatedCode = updatePhoneNumber(phoneNumber: countryCodeToRemove!, replacePlusSign: true)
        //remove countryCode
        let replacedNUmber = fullPhoneNumber.replacingOccurrences(of: updatedCode, with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                print("Code \(countryCodeLetters)")
                print("full number \(fullPhoneNumber)")
                print("code to remove \(updatedCode)")
                print("clean number is \(replacedNUmber)")
        return replacedNUmber
    }

    
    fileprivate func splitDataInToSection() {
        // set section title "" at initial
        var sectionTitle: String = ""
        // iterate all records from array
        for i in 0..<self.matchedUsers.count {
            // get current record
            let currentUser = self.matchedUsers[i]
            // find first character from current record
            let firstChar = currentUser.firstname.first!
            // convert first character into string
            let firstCharString = "\(firstChar)"
            // if first character not match with past section title then create new section
            if firstCharString != sectionTitle {
                // set new title for section
                sectionTitle = firstCharString
                // add new section having key as section title and value as empty array of string
                self.allUsersGrouped[sectionTitle] = []
                // append title within section title list
                self.sectionTitleList.append(sectionTitle)
            }
            // add record to the section
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
        tableView.reloadData()
    }
    
}

//MARK: - Extensions
//search
extension ContactsTableViewController: UISearchResultsUpdating{
    
    func updateSearchResults(for searchController: UISearchController) {
        FilteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func FilteredContentForSearchText(searchText:String, scope:String="All"){
        filteredMatchedUsers = matchedUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
}
//tap delegate
extension ContactsTableViewController: UsersTableViewCellDelegate{
    
    func DidTapProfilePic(IndexPath: IndexPath) {
        //to pass data
        let profileViewcontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileViewOfUser") as! ProfilePageTableViewController
        
        var user:FUser!
        
        if searchController.isActive && searchController.searchBar.text != ""{
            user = filteredMatchedUsers[IndexPath.row]
        }else{
            let sectionTitle = self.sectionTitleList[IndexPath.section]
            let users = self.allUsersGrouped[sectionTitle]
            user = users![IndexPath.row]
        }
        profileViewcontroller.user = user
        //present using navigation controller
        self.navigationController?.pushViewController(profileViewcontroller, animated: true)
    }
}
