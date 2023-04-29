//
//  SearchPopupViewController.swift
//  faer
//
//  Created by pluto on 26.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import Hero

class SearchPopupViewController: UIViewController {
    
    static let storyboardName: String = "SearchPopup"
    
    static let storyboardID: String = "SearchPopupViewController"
        
    static public func fromStoryboard() -> SearchPopupViewController? {
        return UIStoryboard(name: SearchPopupViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier : SearchPopupViewController.storyboardID) as? SearchPopupViewController
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    
    @IBOutlet weak var tableView: UITableView!
    
    private var datasource: [Int: [String]]?
    
    private var defaultDatasource: [Int: [String]] = [0: ["Sweater", "Dresses", "Winter Boots", "Tops", "Cashmere", "Convertible Backpacks"]]

    private var suggestionsDatasource: [Int: [String]]?
    
    private var cachedSectionHeader: SearchPopupSectionHeaderView?
    
    private var isRefreshing: Bool = false
    
    private var defaultQuery: String?
    
    private var searchBox: SearchBox?
    
    private var settings: ItemListSettings?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        // workaround to make the section header disappear like with grouped style see https://stackoverflow.com/questions/1074006/is-it-possible-to-disable-floating-headers-in-uitableview-with-uitableviewstylep
        let dummyViewHeight = CGFloat(40)
        self.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.size.width, height: dummyViewHeight))
        self.tableView.contentInset = UIEdgeInsets(top: -dummyViewHeight, left: 0, bottom: 0, right: 0)
        
        // configure tableview
        self.setNeedsStatusBarAppearanceUpdate()
        self.configureSearchBox()
        
        self.loadDefaultDatasource()
    }
    
    private func loadDefaultDatasource() {
        
        let defaultSize: Int = 20 // number of suggestions fetched at a time from API
        
        guard self.suggestionsDatasource == nil else {
            self.tableView?.reloadSections([0], with: .automatic)
            return
        }
        
        SearchAutoCompleteService.suggestions(size: defaultSize) { [weak self] (result, error) in
            
            if let suggestions = (result?.items.map { return $0.value }) {
                self?.suggestionsDatasource = [0: suggestions]
            } else {
                self?.suggestionsDatasource = self?.defaultDatasource
            }
            
            DispatchQueue.main.async {
                guard (!(self?.isRefreshing ?? true)) else { return }
                self?.datasource = self?.suggestionsDatasource
                self?.tableView?.reloadSections([0], with: .automatic)
            }
        }
    }
    
    private func configureSearchBox() {
        let frame: CGRect = self.navigationController?.navigationBar.frame ?? CGRect.zero
        let container: UIView = UIView(frame: frame)
        container.backgroundColor = .red
        self.searchBox = SearchBox.fromXIB()
        self.searchBox?.delegate = self
        container.addSubview(searchBox!)
        searchBox?.translatesAutoresizingMaskIntoConstraints = false
        searchBox?.leftAnchor.constraint(equalTo: container.leftAnchor, constant: 0).isActive = true
        searchBox?.rightAnchor.constraint(equalTo: container.rightAnchor, constant: 0).isActive = true
        searchBox?.topAnchor.constraint(equalTo: container.topAnchor, constant: 0).isActive = true
        searchBox?.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: 0).isActive = true
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.addSubview(container)
        
        self.searchBox?.searchField.hero.id = SearchResultViewController.searchFieldHeroId
        self.searchBox?.searchField.hero.modifiers = [.scale()]
    }
    
    @objc
    func handleCancelBtn(sender: UIButton) {
        self.hero.dismissViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()

        if let _ = self.defaultQuery {
            self.updateQuery(text: self.defaultQuery!)
        }
    }
    
    // MARK: - Handle Query Text Field Editing
    
    private func loadSuggestions(for text: String) {
        
        guard
            !self.isRefreshing
        else { return }
        
        self.isRefreshing = true
        
        let defaultSize: Int = 20 // number of suggestions fetched at a time from API
        
        SearchAutoCompleteService.using(text: text, size: defaultSize) { [weak self] (result, error) in
            
            guard let _ = result, error == nil, result!.items.count > 0 else {
                DispatchQueue.main.async {
                    self?.isRefreshing = false
                }
                return
            }
            
            self?.datasource?[0] = result!.items.map { return $0.value }
            
            DispatchQueue.main.async {
                self?.tableView?.reloadSections([0], with: .automatic)
                self?.isRefreshing = false
            }
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }
 
    private func updateQuery(text: String) {
        self.searchBox?.searchField.text = text
        self.loadSuggestions(for: text)
    }
    
    func configure(settings: ItemListSettings?) {
        
        guard let _ = settings else {
            return
        }
        
        if let query = settings?.query as? String {
            self.defaultQuery = query
        }
        
    }

}

extension SearchPopupViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.datasource?.keys.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datasource?[section]?.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchPopupTableViewCell.resuseIdentifier, for: indexPath) as! SearchPopupTableViewCell
        
        // Configure the cell...
        
        guard let _ = self.datasource, let queries = self.datasource?[indexPath.section], queries.indices.contains(indexPath.row) else { return cell }
        
        cell.title?.text = queries[indexPath.row].capitalized
        
        return cell
    }
    
}


extension SearchPopupViewController: UITableViewDelegate {
    
    private func sectionHeaderHeight() -> CGFloat {
        return 80
    }
    
    private func sectionHeader(title: String) -> UIView? {
        
        if self.cachedSectionHeader == nil {
            self.cachedSectionHeader = SearchPopupSectionHeaderView(frame: CGRect(x: 0, y: 0, width: 100, height: self.sectionHeaderHeight()))
        }
        
        self.cachedSectionHeader!.title = title
        return self.cachedSectionHeader
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.sectionHeader(title: "Categories")
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return self.sectionHeaderHeight()
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = self.tableView?.cellForRow(at: indexPath) else {
            return
        }
        
        cell.setSelected(false, animated: true)
        
        guard let _ = self.datasource, let queries = self.datasource?[0], queries.indices.contains(indexPath.row) else { return }
        
        let query: String = queries[indexPath.row]
        
        self.searchBox?.searchField.text = query
        
        self.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: ItemListSettings(query: query))

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.searchBox?.searchField.resignFirstResponder()
    }
}

extension SearchPopupViewController: SearchBoxDelegate {
    
    func cancelTapped(view: SearchBox) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchFieldShouldClear() -> Bool {
    //    self.loadDefaultDatasource() // already handled by searchFieldChanged
        return true
    }
    
    func searchBtnTriggered(text: String) {
        self.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: ItemListSettings(query: text))
    }
    
    func searchFieldChanged(text: String) {
        if text == "" { // text field cleared via clear button or backspace
            self.datasource = self.suggestionsDatasource
            self.tableView?.reloadData()
            return
        }
        
        self.loadSuggestions(for: text)
    }

}
