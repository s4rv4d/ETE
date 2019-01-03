//
//  ChatsViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 11/23/18.
//  Copyright © 2018 Sarvad shetty. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController {
    
    //MARK: - Variables
    var recentChats:[NSDictionary] = []
    var filterChats:[NSDictionary] = []
    var recentListener:ListenerRegistration!
    let searchController = UISearchController(searchResultsController: nil)
    
    //MARK: - IBOutlets
    @IBOutlet weak var recentChatTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //navigation bar setup
        navigationController?.navigationBar.prefersLargeTitles = true
        //seearch setup
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        //tableview stuff
        TableviewDelegateSetup()
//        SetTableViewHeader()
    }
    
    override func viewDidLayoutSubviews() {
        SetTableViewHeader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        LoadRecentChats()
        recentChatTableView.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        recentListener.remove()
    }
    

    //MARK: - IBActions
    @IBAction func NewMessage(_ sender: UIBarButtonItem) {
        SelectUserForChat(isGroup:false)
    }
    
}

extension ChatsViewController:UITableViewDelegate,UITableViewDataSource{
    //MARK: - TableView functions
    func TableviewDelegateSetup(){
        recentChatTableView.delegate = self
        recentChatTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("we have \(recentChats.count) recents")
        if searchController.isActive && searchController.searchBar.text != ""{
            return filterChats.count
        }else{
            return recentChats.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recentChatTableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath) as! RecentChatTableViewCell
        //configuring cell
        cell.delegate = self
        var recent:NSDictionary!
        if searchController.isActive && searchController.searchBar.text != ""{
            recent = filterChats[indexPath.row]
        }else{
            recent = recentChats[indexPath.row]
        }
        
        cell.CellGenerate(recentChat: recent, index: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        recentChatTableView.deselectRow(at: indexPath, animated: true)
        var recent:NSDictionary!
        if searchController.isActive && searchController.searchBar.text != ""{
            recent = filterChats[indexPath.row]
        }else{
            recent = recentChats[indexPath.row]
        }
        
        //restart chat for the ones who have deleted the recent chat
        RestartRecentChat(recent: recent)
        
        //show chat view
        let messageVC = MessageViewController()
        //hide tab bar
        messageVC.hidesBottomBarWhenPushed = true
        messageVC.memberToPush = (recent[kMEMBERSTOPUSH] as? [String])!
        messageVC.memberids = (recent[kMEMBERS] as? [String])!
        messageVC.chatRoomId = (recent[kCHATROOMID] as? String)!
        messageVC.recentID = (recent[kRECENTID] as? String)!
        //nav bat updates
        messageVC.titleName = (recent[kWITHUSERFULLNAME] as? String)!
        //checking if group or not
        messageVC.isGroup = (recent[kTYPE] as! String) == kGROUP
        navigationController?.pushViewController(messageVC, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var tempDict:NSDictionary!
        if searchController.isActive && searchController.searchBar.text != ""{
            tempDict = filterChats[indexPath.row]
        }else{
            tempDict = recentChats[indexPath.row]
        }
        //for dynamic change of mute button title
        var muteTitle = "Unmute"
        var mute = false
        //to check if the user can send current logged in user messages notifications
        if (tempDict[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()){
            //if yes then ask for mute
            muteTitle = "Mute"
            mute = true
        }
        //delete action
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            print("delete \(indexPath)")
            self.recentChats.remove(at: indexPath.row)
            DeleteRecentChat(recentChatDict: tempDict)
            self.recentChatTableView.reloadData()
            
        }
        //mute action
        let muteAction = UITableViewRowAction(style: .default, title: muteTitle) { (action, indexPath) in
            print("mute \(indexPath)")
            self.UpdatePushMembers(recent: tempDict, mute: mute)
        }
        muteAction.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
        return [deleteAction,muteAction]
    }
    
    //MARK: - LOAD
    func LoadRecentChats(){
        //to listen to only recent updates
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else {return}
            self.recentChats = []
            if !snapshot.isEmpty{
                //get all snapshots,convert into dictionary and put in array and sort it using NSSortDescriptor
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                //parse through all messages
                for recent in sorted{
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil{
                        
                        //update user image access the user image from recent then access user
                        //recent[kavatar] = new avatar url
 
                        self.recentChats.append(recent)
                    }
                }
                self.recentChatTableView.reloadData()
            }
        })
    }
    //Mark: - Customtable view header
    func SetTableViewHeader(){
        //header view
        let hdView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 45))
        //button view for creating group
        let grpButtonView = UIView(frame: CGRect(x: 0, y: 5, width: view.frame.width, height: 35))
        //create the button
        let grpButton = UIButton(frame: CGRect(x: view.frame.width - 110, y: 10, width: 100, height: 20))
        //target
        grpButton.addTarget(self, action: #selector(self.GroupButtonTapped), for: .touchUpInside)
        grpButton.setTitle("New Group", for: .normal)
        grpButton.setTitleColor(#colorLiteral(red: 0.2540222406, green: 0.6071330905, blue: 0.9695068002, alpha: 1), for: .normal)
        
        //bottom line to separate header from table view
        let bottomLineView = UIView(frame: CGRect(x: 0, y: hdView.frame.height - 1, width: view.frame.width, height: 1))
        bottomLineView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        //add views
        print("dhgashjdgashjgadhjdgadhjsgdashj \(view.frame.width)")
        grpButtonView.addSubview(grpButton)
        hdView.addSubview(grpButtonView)
        hdView.addSubview(bottomLineView)

        
        recentChatTableView.tableHeaderView = hdView
    }
    
    @objc func GroupButtonTapped(){
        print("new group add tapped")
        SelectUserForChat(isGroup: true)
    }
    
    //MARK: - Helper functions
    func UpdatePushMembers(recent:NSDictionary,mute:Bool){
        var memberToPush = recent[kMEMBERSTOPUSH] as! [String]
        if mute{
            let index = memberToPush.index(of:FUser.currentId())
            memberToPush.remove(at: index!)
        }else{
            memberToPush.append(FUser.currentId())
        }
        
        //save the changes
        UpdateExistingRecentWithNewValues(chatroomID: recent[kCHATROOMID] as! String, members: recent[kMEMBERS] as! [String], withValues: [kMEMBERSTOPUSH:memberToPush])
    }
    
    func SelectUserForChat(isGroup:Bool){
        //access the users storyboard using storyboardID and present using navigation push method
        let contactVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "contactsview") as! ContactsTableViewController
        contactVC.isGroup = isGroup
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
}

extension ChatsViewController:RecentChatTableViewCellDelegate{
    func ProfilePicTapped(index: IndexPath) {
        var recent:NSDictionary!
        if searchController.isActive && searchController.searchBar.text != ""{
            recent = filterChats[index.row]
        }else{
            recent = recentChats[index.row]
        }
        
        if recent[kTYPE] as! String == kPRIVATE{
            reference(.User).document(recent[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
                guard let snapshot = snapshot else {return}
                if snapshot.exists{
                    //create a current dictionary
                    let userDict = snapshot.data() as! NSDictionary
                    let tempUser = FUser(_dictionary: userDict)
                    self.ShowUserProfile(user: tempUser)
                }
            }
        }
    }
    
    func ShowUserProfile(user:FUser){
        let profileVc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileViewOfUser") as! ProfilePageTableViewController
        profileVc.user = user
        
        self.navigationController?.pushViewController(profileVc, animated: true)
    }
}

extension ChatsViewController:UISearchResultsUpdating{
    
    //MARK: - Search results methods
    func updateSearchResults(for searchController: UISearchController) {
        //insert the searchbar text inside function
        FilterContentForSearch(searchText: searchController.searchBar.text!)
    }
    
    func FilterContentForSearch(searchText:String,scope:String="All"){
        filterChats = recentChats.filter({ (rc) -> Bool in
            return (rc[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
        })
        
        //reload data after filtered users
        recentChatTableView.reloadData()
    }
}
