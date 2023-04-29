//
//  SearchAutocompleteTableViewController.swift
//  faer
//
//  Created by pluto on 06.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

protocol SearchAutocompleteTableViewControllerDelegate :class {
    func didSelect(text: String)
}

class SearchAutocompleteTableViewController: UITableViewController {
    
    static let storyboardName: String = "SearchAutocompleteTableViewController"
    
    weak var delegate: SearchAutocompleteTableViewControllerDelegate?
    
    private var resultSize: Int = 3
    
    private var isRefreshing: Bool = false
    
    private lazy var suggestions: [String] = [] // dataSource
    
    // automatically updated preferredHeight when used as child VC || IMPORTANT: use reloadSection or similar instead of .reloadData as reloadData doesn't trigger resize
    private let contentSizeKeyPath: String = "contentSize"
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard let view = object as? UITableView, view == self.tableView, keyPath == self.contentSizeKeyPath , let _ = change?[NSKeyValueChangeKey.newKey] as? CGSize else {
            return
        }
        self.preferredContentSize = self.tableView.contentSize
    }
    
    deinit {
        self.tableView.removeObserver(self, forKeyPath: self.contentSizeKeyPath)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.addObserver(self, forKeyPath: self.contentSizeKeyPath, options: .new, context: nil)
        
        // init resultSize according to screenHeight, hacky. TODO: Refactor design
        switch UIScreen.main.nativeBounds.height {
        case 960:
            self.resultSize = 0 // .iPhone4_4S
        case 1136:
            self.resultSize = 0 // .iPhones_5_5s_5c_SE
        case 1334:
            self.resultSize = 3 // .iPhones_6_6s_7_8
        case 1920, 2208:
            self.resultSize = 5 // .iPhones_6Plus_6sPlus_7Plus_8Plus
        case 2436:
            self.resultSize = 6 // .iPhoneX
        default:
            self.resultSize = 8 // iPads et al
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.suggestions.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchAutocompleteTableViewCell.resuseIdentifier, for: indexPath) as! SearchAutocompleteTableViewCell
        
        // Configure the cell...
        guard self.suggestions.indices.contains(indexPath.row) else { return cell } // otherwise might crash. TODO: find out when crashing happens
        cell.label?.text = self.suggestions[indexPath.row]
        
        return cell
    }
    
    // MARK: - Table view data delegate
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate?.didSelect(text: self.suggestions[indexPath.row])
    }
    
    // MARK: - public interfaces
    
    func clear() {
        self.suggestions.removeAll()
        self.tableView.rowHeight = 0
        self.tableView.separatorStyle = .none
        self.tableView?.reloadSections([0], with: .none)
    }
    
    func update(for text: String) {
        
        guard !self.isRefreshing else { return }
        
        // hack; current design doesn't enough display space to show autocomplete for iPhone 4 / 5
        if self.resultSize == 0 {
            self.clear()
            return
        }
        self.isRefreshing = true
        SearchAutoCompleteService.using(text: text, size: self.resultSize) { [weak self] (result, error) in
            guard let _ = result, error == nil, result!.items.count > 0 else {
                DispatchQueue.main.async {
                    self?.clear()
                    self?.isRefreshing = false
                }
                return
            }
            
            self?.suggestions = result!.items.map { return $0.value }
            
            DispatchQueue.main.async {
                self?.tableView.rowHeight = UITableView.automaticDimension
                self?.tableView.separatorStyle = .singleLineEtched
                self?.tableView?.reloadSections([0], with: .automatic)
                self?.isRefreshing = false
            }
        }
    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}





// MARK: - UISearchBar Delegate
extension SearchAutocompleteTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
    }
}

// MARK: - UISearchResultsUpdating Delegate
extension SearchAutocompleteTableViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
       // let searchBar = searchController.searchBar        
    }
}


