//
//  InviteUserTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 1/1/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase

class InviteUserTableViewController: UITableViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var headerView: UIView!
    
    //MARK: - Variables
    var allUsers = [FUser]()
    var allUsersGroupped = NSDictionary() as! [String:[FUser]]
    var sectionTiltes = [String]()
    var newMemberIds:[String] = []
    var currentMemberIds:[String] = []
    var group:NSDictionary!
    
    override func viewWillAppear(_ animated: Bool) {
        LoadUsers(filter: kCITY)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Users"
        tableView.tableFooterView = UIView()
        
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.DoneTapped))]
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        currentMemberIds = group[kMEMBERS] as! [String]
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return allUsersGroupped.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        let sectiont = self.sectionTiltes[section]
        let users = allUsersGroupped[sectiont]
        return users!.count
    }
    
    //MARK: - Table view delegate
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UsersTableViewCell
        let sectionTitle = self.sectionTiltes[indexPath.section]
        let users = self.allUsersGroupped[sectionTitle]
        cell.GenerateCellWith(fuser: users![indexPath.row], indexPath: indexPath)
        //delegate
        cell.delegate = self
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTiltes[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.sectionTiltes
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        //jumps to section when you tap on it
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionT = self.sectionTiltes[indexPath.section]
        let users = self.allUsersGroupped[sectionT]
        let selectedUser = users![indexPath.row]
        
        //to check if already in group
        if currentMemberIds.contains(selectedUser.objectId){
            ProgressHUD.showError("User already in group")
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath){
//            if cell.accessoryType == .checkmark{
//                cell.accessoryType = .none
//            }else{
//                cell.accessoryType = .checkmark
//            }
//
            cell.accessoryType = (cell.accessoryType == .checkmark) ? .none:.checkmark
        }
        
        //add/remove
        let seleected = newMemberIds.contains(selectedUser.objectId)
        
        if seleected{
            //remove (when checkmark is none)
            let index = newMemberIds.index(of:selectedUser.objectId)
            newMemberIds.remove(at: index!)
        }else{
            //add
            newMemberIds.append(selectedUser.objectId)
        }
        print("new members \(newMemberIds)")
        self.navigationItem.rightBarButtonItem?.isEnabled = newMemberIds.count > 0
    }
    
    //MARK: - IBActions
    @IBAction func filterSegmentValue(_ sender: UISegmentedControl) {
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
    
    //MARK: - Functions
    @objc func DoneTapped(){
        //combine new members with old members
        UpdateGroup(group: group)
    }
    
    func UpdateGroup(group:NSDictionary){
        let tempMember = currentMemberIds + newMemberIds
        let tempMeberToPush = group[kMEMBERSTOPUSH] as! [String] + newMemberIds
        
        let withValues = [kMEMBERS:tempMember,kMEMBERSTOPUSH:tempMeberToPush]
        
        Group.UpdateGroup(groupID: group[kGROUPID] as! String, withValues: withValues)
        //create new recents for new members
        CreateRecentForNewMemebersG(groupID: group[kGROUPID] as! String, groupName: group[kNAME] as! String, membersToPush: tempMeberToPush, avatar: group[kAVATAR] as! String)
        
        //update existing recent too
        UpdateExistingRecentWithNewValues(chatroomID: group[kGROUPID] as! String, members: tempMember, withValues: withValues)
        
        //start group chat
        GoToChat(membersToPush: tempMeberToPush, members: tempMember)
    }
    
    func GoToChat(membersToPush:[String],members:[String]){
        let chatVC = MessageViewController()
        chatVC.titleName = group[kNAME] as! String
        chatVC.memberToPush = membersToPush
        chatVC.memberids = members
        chatVC.chatRoomId = group[kGROUPID] as! String
        chatVC.isGroup = true
        chatVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
    
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
                if !sectionTiltes.contains(sectionTitle){
                    self.sectionTiltes.append(sectionTitle)
                }
            }
            //then append to array
            self.allUsersGroupped[firstCharacterToString]!.append(currentUser)
        }
        
    }


}

//MARK: - Extensions
extension InviteUserTableViewController: UsersTableViewCellDelegate{
    
    func DidTapProfilePic(IndexPath: IndexPath) {
        //print to check
        print("User at \(IndexPath)")
        
        //to pass data
        let profileViewcontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileViewOfUser") as! ProfilePageTableViewController
        let sectionTitle = self.sectionTiltes[IndexPath.section]
        let users = self.allUsersGroupped[sectionTitle]
        profileViewcontroller.user = users![IndexPath.row]
        
        //present using navigation controller
        self.navigationController?.pushViewController(profileViewcontroller, animated: true)
    }
}
