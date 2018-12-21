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
    
    //MARK:Variables
    var recentChats:[NSDictionary] = []
    var filterChats:[NSDictionary] = []
    var recentListener:ListenerRegistration!
    
    //MARK:IBOutlets
    @IBOutlet weak var recentChatTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //navigation bar setup
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //tableview stuff
        TableviewDelegateSetup()
        SetTableViewHeader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        LoadRecentChats()
        recentChatTableView.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        recentListener.remove()
    }
    

    //MARK:IBActions
    @IBAction func NewMessage(_ sender: UIBarButtonItem) {
        //access the users storyboard using storyboardID and present using navigation push method
        let userViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "usersTableView") as! UsersTableViewController
        self.navigationController?.pushViewController(userViewController, animated: true)
    }
    
}

extension ChatsViewController:UITableViewDelegate,UITableViewDataSource{
    func TableviewDelegateSetup(){
        recentChatTableView.delegate = self
        recentChatTableView.dataSource = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("we have \(recentChats.count) recents")
        return recentChats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recentChatTableView.dequeueReusableCell(withIdentifier: "recentCell", for: indexPath) as! RecentChatTableViewCell
        //configuring cell
        let recent = self.recentChats[indexPath.row]
        cell.CellGenerate(recentChat: recent, index: indexPath)
        return cell
    }
    
    //MARK:LOAD
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
        let hdView = UIView(frame: CGRect(x: 0, y: 0, width: recentChatTableView.frame.width, height: 45))
        //button view for creating group
        let grpButtonView = UIView(frame: CGRect(x: 0, y: 5, width: recentChatTableView.frame.width, height: 35))
        //create the button
        let grpButton = UIButton(frame: CGRect(x: recentChatTableView.frame.width - 110, y: 10, width: 100, height: 20))
        //target
        grpButton.addTarget(self, action: #selector(self.GroupButtonTapped), for: .touchUpInside)
        grpButton.setTitle("New Group", for: .normal)
        grpButton.setTitleColor(#colorLiteral(red: 0.2540222406, green: 0.6071330905, blue: 0.9695068002, alpha: 1), for: .normal)
        //bottom line to separate header from table view
        let bottomLineView = UIView(frame: CGRect(x: 0, y: hdView.frame.height - 1, width: recentChatTableView.frame.width, height: 1))
        bottomLineView.backgroundColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        
        //add views
        grpButtonView.addSubview(grpButton)
        hdView.addSubview(grpButtonView)
        hdView.addSubview(bottomLineView)
        recentChatTableView.tableHeaderView = hdView
    }
    
    @objc func GroupButtonTapped(){
        print("new group add tapped")
    }
}

extension ChatsViewController:RecentChatTableViewCellDelegate{
    func ProfilePicTapped(index: IndexPath) {
        let reChat = recentChats[index.row]
        
        if reChat[kTYPE] as! String == kPRIVATE{
            reference(.User).document(reChat[kWITHUSERUSERID] as! String).getDocument { (snapshot, error) in
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
