//
//  SearchViewController.swift
//  faer
//
//  Created by pluto on 17.02.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import Hero

class SearchViewController: UIViewController {
    
    static let storyboardIdentifier: String = "Search"
    static let storyboardName: String = "Search"
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    
    @IBOutlet weak var container: UIView!
    private var containerOriginTopMargin: CGFloat!
    private var containerOriginBottomMargin: CGFloat!
    
    static let storyboardID: String = "searchSB"
    
    private var kbVC: SearchInputTypeViewController!
    private var micVC: SearchInputTypeViewController!
    private var cameraVC: SearchInputTypeViewController!
    private var currentVC: UIViewController!
    private var searchResultNC: SearchResultNavigationController!
    private let lastSearchInputTypeKey = "lastSearchInputTypeKey"
    private var lastSearchInputType: SearchInputType! {
        didSet {
            UserDefaults.standard.set(self.lastSearchInputType.rawValue, forKey: self.lastSearchInputTypeKey)
        }
    }
    
    private var query: Any?
    private var settings: ItemListSettings?
    private var list: ItemList?
    
    override var childForStatusBarStyle: UIViewController? {
        return currentVC
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.kbVC = (UIStoryboard(name: "Search", bundle: nil).instantiateViewController(withIdentifier: "searchKeyboardSB")) as? SearchInputTypeViewController
        self.micVC = (UIStoryboard(name: "Search", bundle: nil).instantiateViewController(withIdentifier: "searchVoiceSB")) as? SearchInputTypeViewController
        self.cameraVC = (UIStoryboard(name: "Search", bundle: nil).instantiateViewController(withIdentifier: "searchCameraSessionSB")) as? SearchInputTypeViewController
        
        self.kbVC.delegate = self
        self.micVC.delegate = self
        self.cameraVC.delegate = self
        
        self.lastSearchInputType = SearchInputType(rawValue: UserDefaults.standard.integer(forKey: self.lastSearchInputTypeKey)) ?? .microphone
        
        // Observers to handle AppNotifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentProduct, object: nil) // handle event alerts
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentSearchResult, object: nil) // handle event alerts

    }
    
    @objc
    private func handle(notification: NSNotification) {
        guard self.isVisible() else { return }
        
        guard let userInfo = AppNotifications.UserInfo(notification.userInfo) else { return }
        
        self.performSegue(withIdentifier: userInfo.segue.rawValue, sender: userInfo.payload)
    }


    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()


        // setup inital search input view
        switch self.lastSearchInputType {
        case .keyboard?:
            self.configureDefault(searchInputVC: self.kbVC)
            self.kbVC.inputAutoActivate = true
        case .microphone?:
            self.configureDefault(searchInputVC: self.micVC)
        case .camera?:
            self.configureDefault(searchInputVC: self.cameraVC)
        default:
            return
        }
        
    }
    
    private func configureDefault(searchInputVC: SearchInputTypeViewController) {
        searchInputVC.view.frame = self.container.bounds
        self.container.addSubview(searchInputVC.view)
        self.addChild(searchInputVC)
        searchInputVC.didMove(toParent: self)
        self.currentVC = searchInputVC
    }
    
    private func toogleParentPageControlfNeeded() {
        guard
            let _ = self.currentVC as? SearchInputTypeViewController,
            let _ = self.parent as? UINavigationController,
            let pc = self.parent!.parent as? MainPageViewController
            else { return }
        
        if (self.currentVC as! SearchInputTypeViewController).requiresFullScreen {
            pc.pageControl?.isHidden = true
        } else {
            pc.pageControl?.isHidden = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.toogleParentPageControlfNeeded()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard
            let _ = self.currentVC as? SearchInputTypeViewController,
            let _ = self.parent as? UINavigationController,
            let pc = self.parent!.parent as? MainPageViewController
            else { return }
        pc.pageControl?.isHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func displayNoSearchResults(query: Any, list: ItemList?) {
        let noSearchResultVC: NoSearchResultViewController = (UIStoryboard(name: SearchViewController.storyboardIdentifier, bundle: nil).instantiateViewController(withIdentifier: NoSearchResultViewController.storyboardIdentifier)) as! NoSearchResultViewController
        noSearchResultVC.delegate = self
        noSearchResultVC.previousInputType = self.lastSearchInputType
        noSearchResultVC.query = self.query
        noSearchResultVC.list = list
        
        Hero.shared.transition(from: self.currentVC, to: noSearchResultVC, in: self.container, completion: { (completed) in
            self.currentVC = noSearchResultVC
            self.toogleParentPageControlfNeeded()
            self.addChild(noSearchResultVC)
            noSearchResultVC.didMove(toParent: self)
        })
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }
    
}

extension SearchViewController: SearchInputTypeDelegate {
    
    func changeSearchInputType(requested: SearchInputType) {
        
        let nextVC: SearchInputTypeViewController
        switch requested {
        case .keyboard:
            nextVC = self.kbVC
            nextVC.inputAutoActivate = true
            self.lastSearchInputType = .keyboard

        case .microphone:
            nextVC = self.micVC
            self.lastSearchInputType = .microphone

        case .camera:
            nextVC = self.cameraVC
            self.lastSearchInputType = .camera
            
        }
        
        if nextVC == self.currentVC { // in case of no search result
            return
        }
        
        Hero.shared.transition(from: self.currentVC, to: nextVC, in: self.container, completion: { (completed) in
            self.currentVC = nextVC
            self.toogleParentPageControlfNeeded()
            self.addChild(nextVC)
            nextVC.didMove(toParent: self)
        })
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    func requestSearch(sender: SearchInputTypeViewController, query: Any) {
        Log.Tap.search(query)
        
        if sender is NoSearchResultViewController { // update query in keyboard in case user search for alternative
            self.kbVC.updatedQuery(value: query as! String)
        }
        
        // perform search
        
        self.query = query
        
        guard Network.shared.isReachable() else {
            BannerNotification.noInternetConnection()
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            sender.transitionForSearching(visible: true)
        }
        
        self.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: query)
        
        sender.transitionForSearching(visible: false)
        
    }
    
    func requestItemWeb(item: Item) {
        self.performSegue(withIdentifier: CommonSegues.map.rawValue, sender: item.stores)
    }
    
}

extension SearchViewController: SearchResultDelegate {
    func dismiss(sender: SearchResultViewController) {
        sender.navigationController?.hero.dismissViewController()
        self.query = nil
        self.list = nil
    }
    
    func updatedSettings(value: ItemListSettings) {
        guard
            let _ = self.currentVC as? SearchInputTypeViewController
            else { return }
        (self.currentVC as! SearchInputTypeViewController).updatedQuery(value: value.query)
    }
}
