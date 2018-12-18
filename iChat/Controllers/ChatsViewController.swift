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
        LoadRecentChats()
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
}
