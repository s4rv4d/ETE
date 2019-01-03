//
//  PastCallsTableViewController.swift
//  iChat
//
//  Created by Sarvad shetty on 1/3/19.
//  Copyright © 2019 Sarvad shetty. All rights reserved.
//

import UIKit
import ProgressHUD
import FirebaseFirestore

class PastCallsTableViewController: UITableViewController {
    
    //MARK: - Variables
    var allCalls:[Call] = []
    var filteredCalls:[Call] = []
    
    //appdelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //search
    let searchController = UISearchController(searchResultsController: nil)
    
    //listeners
    var callListener:ListenerRegistration!
    
    //MARK: - Main
    override func viewWillAppear(_ animated: Bool) {
        //load all calls
        LoadCalls()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        callListener.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if searchController.isActive && searchController.searchBar.text != ""{
            return filteredCalls.count
        }else{
            return allCalls.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PastCallsTableViewCell
        var call:Call!
        if searchController.isActive && searchController.searchBar.text != ""{
            call = filteredCalls[indexPath.row]
        }else{
            call = allCalls[indexPath.row]
        }
        
        cell.CellGenerate(call: call)
        return cell
    }
    
    //MARK: - TableView Delegate
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            
            var tempCall:Call!
            
            if searchController.isActive && searchController.searchBar.text != ""{
                tempCall = filteredCalls[indexPath.row]
                filteredCalls.remove(at: indexPath.row)
            }else{
                tempCall = allCalls[indexPath.row]
                allCalls.remove(at: indexPath.row)
            }
            
            tempCall.DeleteCall()
            self.tableView.reloadData()
        }
    }
    
    //MARK: - Functions
    func LoadCalls(){
        callListener = reference(.Call).document(FUser.currentId()).collection(FUser.currentId()).order(by: kDATE, descending: true).limit(to: 20).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else{return}
            self.allCalls = []
            
            if !snapshot.isEmpty{
                let sortedDictionary = dictionaryFromSnapshots(snapshots: snapshot.documents)
                
                for callDict in sortedDictionary{
                    let call = Call(_dictionary: callDict)
                    self.allCalls.append(call)
                }
            }
            
            self.tableView.reloadData()
        })
    }

}

//MARK: - Extensions
extension PastCallsTableViewController: UISearchResultsUpdating{
    
    func updateSearchResults(for searchController: UISearchController) {
        //insert the searchbar text inside function
        FilterContentForSearch(searchText: searchController.searchBar.text!)
    }
    
    func FilterContentForSearch(searchText:String,scope:String="All"){
        filteredCalls = allCalls.filter({ (call) -> Bool in
            var callerName:String!
            if call.callerID == FUser.currentId(){
                callerName = call.withUserFullName
            }else{
                callerName = call.callerFullName
            }
            return (callerName).lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
}
