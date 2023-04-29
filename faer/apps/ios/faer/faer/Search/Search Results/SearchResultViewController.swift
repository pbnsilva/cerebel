//
//  SearchResultViewController
//  test
//
//  Created by pluto on 12.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SquareMosaicLayout
import MessageUI
import FirebaseAnalytics
import Hero
import SDWebImage
import CoreLocation

protocol SearchResultDelegate :class {
    func dismiss(sender: SearchResultViewController)
    func updatedSettings(value: ItemListSettings)
}

class SearchResultViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    static let searchFieldHeroId: String = "searchFieldID"
    
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private lazy var locationManager: CLLocationManager = CLLocationManager()
    
    private var productCellHeight: CGFloat!
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    weak var delegate: SearchResultDelegate?
    
    private var searchFilterVisible: Bool = false {
        willSet(newValue) {
            if (newValue) {
                self.displaySearchFilter()
            } else {
                self.hideSearchFilter()
            }
        }
    }
    
    //Data Source
    
    private var settings: ItemListSettings?
    
    private var dataSource: SearchResultViewDataSource?
    // handle prefetching
    private let dataSourceLoadQueue = OperationQueue()
    private var dataSourceLoadOperations = [SearchResultViewDataSource.Section: ItemListLoadOperation]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        
        // register cells
        collectionView?.register(
            UINib(nibName: ProductDetailsView.nibName, bundle: nil),
            forCellWithReuseIdentifier: ProductDetailsView.reuseId
        )
        collectionView?.register(
            UINib(nibName: SearchResultEmptyCollectionViewCell.nibName, bundle: nil),
            forCellWithReuseIdentifier: SearchResultEmptyCollectionViewCell.reuseIdentifer
        )
        
        collectionView?.register(
            UINib(nibName: SearchResultRefreshingCollectionViewCell.nibName, bundle: nil),
            forCellWithReuseIdentifier: SearchResultRefreshingCollectionViewCell.reuseIdentifer
        )
                
        // configure view
        
        collectionView?.prefetchDataSource = self
        
        // update view
        self.productCellHeight = self.view.frame.height * 0.85
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.collectionView?.reloadData()
        }
        
        // disable mem caching to avoid oom crashes
        
        SDImageCache.shared.config.shouldCacheImagesInMemory = false
        
        // Observers to handle AppNotifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentProduct, object: nil) // handle event alerts
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentSearchResult, object: nil) // handle event alerts
        
        self.setNeedsStatusBarAppearanceUpdate()
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.dataSourceLoadQueue.cancelAllOperations()
        self.dataSourceLoadOperations.removeAll()
        SDImageCache.shared.clearMemory()
        for cell in self.collectionView.visibleCells {
            if let productCell = cell as? ProductDetailsView {
                productCell.handleMemoryWarning()
            }
        }
        
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Data source handling
    
    // initializes a new search result loading the data from remote
    private func loadItems(_ settings: ItemListSettings) {
        
        let emptyQuery: String = "<emptyQuery>"
        
        Log.Tap.search(settings.query ?? emptyQuery)
        
        guard Network.shared.isReachable() else {
            BannerNotification.noInternetConnection()
            return
        }
        
        ItemList.using(settings: settings, atOffset: 0, size: ItemList.defaultPageSize) { [weak self] (list, error) in
            guard let _ = self else {
                return
            }
            
            guard error == nil, let _ = list else {
                BannerNotification.warning(title: Messages.failedToLoadSearchResults)
                return
            }
            
            DispatchQueue.main.async {
                self?.settings = settings
                self?.dataSource = SearchResultViewDataSource(list: list!, sectionSize: settings.size)
                self?.configureNavigationBar(suggestions: list?.suggestions)
                self?.collectionView?.reloadData()
                self?.collectionView?.contentOffset = CGPoint.zero
                Log.View.searchResult(settings.query ?? emptyQuery, totalItems: list!.totalItems)
            }
        }
    }
    
    // load data for given section
    fileprivate func loadDataIfNeededForSection(_ section: Int) {

        guard
            let _ = self.settings,
            let _ = dataSource,
            dataSource?.sectionItems[section] == nil
        
        else { return }
        
        let offset: Int = dataSource!.offsetForSection(section)

        guard dataSourceLoadOperations[section] == nil else { // is the section already loaded or loading?
            if let list = dataSourceLoadOperations[section]?.list {
                self.dataSource?.sectionItems[section] = list.items
                self.collectionView?.reloadSections([section])
            }
            
            return // still loading, do nothing
        }
        
        // start loading data for section
        let dataSourceLoadOperation = ItemListLoadOperation(settings: self.settings!, offset: offset, size: self.dataSource!.numberOfItems(section: section))
        dataSourceLoadOperation.completionHandler = { [weak self] (list, error) in
            self?.dataSourceLoadOperations.removeValue(forKey: section)

            guard let _ = list else {
                return
            }
            DispatchQueue.main.async {
                self?.dataSource?.sectionItems[section] = dataSourceLoadOperation.list!.items
                self?.collectionView?.reloadSections([section])
            }
        }
        
        dataSourceLoadQueue.addOperation(dataSourceLoadOperation)
        dataSourceLoadOperations[section] = dataSourceLoadOperation

    }
    
    fileprivate func configureCell(_ cell: ProductDetailsView, _ indexPath: IndexPath) {
        
        guard
            let items = dataSource?.sectionItems[indexPath.section],
            items?.indices.contains(indexPath.row) ?? false,
            let item = items?[indexPath.row]
            else {
                // data for section is not loaded yet, request it
                self.loadDataIfNeededForSection(indexPath.section)
                return
        }
        
        cell.set(item)
        
        cell.delegate = self
        
    }
    
    // updates the VC using the given query
    func configure(query: Any) {
        
        let settings: ItemListSettings
        
        if let _ = query as? ItemListSettings {
            settings = query as! ItemListSettings
        } else {
            settings = ItemListSettings(query: query)
        }
        
        self.settings = settings
        self.loadItems(settings)
        
    }
    
    // initializes a new search result with the provided settings and list
    func configure(settings: ItemListSettings, list: ItemList) {
        
        if list.items.isEmpty {
            self.dataSource = nil
        }
        
        self.settings = settings
        self.dataSource = SearchResultViewDataSource(list: list, sectionSize: settings.size)
        
        self.collectionView?.reloadData()
        self.collectionView?.contentOffset = CGPoint.zero // scroll to top
        self.configureNavigationBar(suggestions: list.suggestions)
    }
    
    /*
     https://stackoverflow.com/questions/25870382/how-to-prevent-status-bar-from-overlapping-content-with-hidesbarsonswipe-set-on
     cancel gesture for filter swipe down
     */
    private func configureNavigationBar(suggestions: [String]?) {
        
        guard
            let nc = self.navigationController as? SearchResultNavigationController,
            let _ = self.dataSource
        else { return }
        
        nc.configureNavigationBar(tags: suggestions ?? [], settings: self.settings)
        nc.navigationBarExtension?.delegate = self
        
        // set title
        let title: String
        
        if let _ = self.settings?.query as? String {
            title = self.settings!.query as! String
        } else {
            if let _ = self.dataSource {
                if self.dataSource?.totalNumberOfItems == 1 {
                    title = "One product found"
                } else {
                    title = "\(self.dataSource!.totalNumberOfItems) products found"
                }

            } else {
                title = ""
            }
        }
        
        let titleLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height))
        titleLabel.text = title
        titleLabel.font = UIFont(name: StyleGuide.fontBold, size: StyleGuide.fontMediumSize)!
        
        let titleTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(titleTapped))
        titleLabel.addGestureRecognizer(titleTap)
        titleLabel.isUserInteractionEnabled = true
        titleLabel.hero.id = SearchResultViewController.searchFieldHeroId
        self.navigationItem.titleView = titleLabel
        
    }
    
    @objc
    private func titleTapped(sender: UITapGestureRecognizer) {
        self.performSegue(withIdentifier: CommonSegues.searchPopup.rawValue, sender: self.settings)
    }
    
    
    // MARK: Search Filter
    private var dummyView: UIView!
    
    private var searchFilterViewHeight:NSLayoutConstraint!
    
    private var searchFilterChildVC: FilterTableViewController?
    
    private func addFakeBackground() {
        // hack: create fake background view
        // this fills the transparent area / safe margin on iphone-x beneath the filters visible when scrolling results and filter open
        dummyView = UIView()
        dummyView.backgroundColor = .white
        self.view.addSubview(dummyView)
        dummyView.translatesAutoresizingMaskIntoConstraints = false
        dummyView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        dummyView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        dummyView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        dummyView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }
    
    private func displaySearchFilter() {
        
        self.addFakeBackground()

        // Create child VC
        
        self.searchFilterChildVC = UIStoryboard(name: FilterTableViewController.storyboardName, bundle: nil).instantiateInitialViewController() as? FilterTableViewController
        guard let _ = searchFilterChildVC else { return }
        self.searchFilterChildVC?.settings = self.settings
        searchFilterChildVC?.delegate = self
        
        // Set child VC
        self.addChild(searchFilterChildVC!)
        
        // Add child VC's view to parent
        self.view.addSubview(searchFilterChildVC!.view)
        
        // Register child VC
        searchFilterChildVC?.didMove(toParent: self)
        
        // Setup constraints for layout
        searchFilterChildVC?.view.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11, *) {
            searchFilterChildVC?.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true // account for iphone-x
        } else {
            searchFilterChildVC?.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        }
        
        searchFilterChildVC?.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        searchFilterChildVC?.view.widthAnchor.constraint(equalTo: self.view.widthAnchor).isActive = true
        searchFilterViewHeight = searchFilterChildVC!.view.heightAnchor.constraint(equalToConstant: searchFilterChildVC!.tableView.contentSize.height)
        searchFilterViewHeight?.isActive = true
        
    }
    
    private func hideSearchFilter() {
        dummyView.removeFromSuperview()
        searchFilterChildVC?.willMove(toParent: nil)
        searchFilterChildVC?.view.removeFromSuperview()
        searchFilterChildVC?.removeFromParent()
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        guard container.preferredContentSize.height > 0 else { return }
        switch container {
        case is FilterTableViewController:
            self.searchFilterViewHeight?.constant = container.preferredContentSize.height // update container height when child tableview resizes
            self.searchFilterChildVC?.tableView.layoutSubviews()
            break
        default:
            break;
        }
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }
    
    // MARK: Navigation
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        
        if #available(iOS 11, *) {
            //            return UIEdgeInsets() // handled by viewSafeAreaInsetsDidChange
        }
        
        guard
            section == 0,
            let nc:SearchResultNavigationController = self.navigationController as? SearchResultNavigationController,
            let _ = nc.navigationBarExtension
            else {
                return UIEdgeInsets()
        }
        
        return UIEdgeInsets(top: nc.navigationBarExtension!.bounds.height, left: 0, bottom: 0, right: 0)
    }
    
}

// MARK: UICollectionViewDataSource
extension SearchResultViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard
            let _ = dataSource,
            dataSource!.totalNumberOfSections > 0 else {
                return 1
        }
        
        return dataSource!.totalNumberOfSections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard
            let _ = dataSource,
            dataSource!.totalNumberOfItems > 0 else {
                return 1
        }

        return dataSource?.numberOfItems(section: section) ?? 1

    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let dataSource = self.dataSource else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchResultRefreshingCollectionViewCell.reuseIdentifer, for: indexPath) as! SearchResultRefreshingCollectionViewCell
            cell.activityIndicator.startAnimating()
            return cell
        }
        
        guard dataSource.totalNumberOfItems > 0 else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: SearchResultEmptyCollectionViewCell.reuseIdentifer, for: indexPath) as! SearchResultEmptyCollectionViewCell
        }
                        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductDetailsView.reuseId, for: indexPath) as? ProductDetailsView else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: SearchResultRefreshingCollectionViewCell.reuseIdentifer, for: indexPath) as! SearchResultRefreshingCollectionViewCell // to prevent crash. if there is data, product detail should be shown
        }
        
        configureCell(cell, indexPath)

        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width, height: self.productCellHeight)
    }
    
}

// MARK: UICollectionViewDataSourcePrefetching
extension SearchResultViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        
        guard let _ = self.dataSource else {
            return
        }
        
        var urls: [URL] = []
        for indexPath in indexPaths {
            // preload items
            if let items = self.dataSource?.sectionItems[indexPath.section], let _ = items {
                for item in items! {
                    guard let _ = item.imageURLs.first else { continue }
                    urls.append(item.imageURLs.first!)
                }
            } else {
                self.loadDataIfNeededForSection(indexPath.section)
            }
            
        }
        SDWebImagePrefetcher.shared.prefetchURLs(urls)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    }
}

// MARK: ProductDetailsViewDelegate

extension SearchResultViewController: ProductDetailsViewDelegate {
    
    private func itemWithView(_ sender: ProductDetailsView) -> Item? {
        guard
            let indexPath = self.collectionView.indexPath(for: sender),
            let item = dataSource?.sectionItems[indexPath.section]??[indexPath.row]
            else { return nil }
        return item
    }
    
    func likeTapped(_ sender: ProductDetailsView) {
        
        guard let item = itemWithView(sender) else { return }
        
        item.isLiked = sender.likeBtn.isSelected
        
    }
    
    func shareTapped(_ sender: ProductDetailsView) {
        
        guard let item = itemWithView(sender) else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [item.shareUrl],
            applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = sender
        activityViewController.popoverPresentationController?.sourceRect = sender.bounds
        
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            guard completed else { return }
            let itemParameters: [String: Any] = Log.serialize(item) // pass by value to avoid retention cycle in AV completion closure
            Log.Tap.share(view: .SearchResult, parameters: itemParameters)
        }
        
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    func storeTapped(_ sender: ProductDetailsView) {
        
        guard let item = itemWithView(sender) else { return }
        
        self.performSegue(withIdentifier: CommonSegues.webView.rawValue, sender: item)
    }
    
    func brandTapped(_ sender: ProductDetailsView) {

        guard let item = itemWithView(sender) else { return }
        
        self.performSegue(withIdentifier: CommonSegues.brandProfile.rawValue, sender: item)

    }
    
    func mapTapped(_ sender: ProductDetailsView) {
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            let refreshAlert = UIAlertController(title: "Open settings", message: "Enable location for Faer in your settings to find stores.", preferredStyle: UIAlertController.Style.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            
            present(refreshAlert, animated: true, completion: nil)
            
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            
            guard let item = itemWithView(sender), let stores = item.stores else { return }
            
            Log.Tap.map(view: .SearchResult, item: item)
            self.performSegue(withIdentifier: CommonSegues.map.rawValue, sender: stores)
            
            break
        }
        
    }
    
}

//MARK: - HeroProgressUpdateObserver

extension SearchResultViewController: HeroProgressUpdateObserver {
    func heroDidUpdateProgress(progress: Double) {
    }
}

extension SearchResultViewController: FilterTableViewControllerDelegate {
    func didUpdate(settings: ItemListSettings) {
        self.loadItems(settings)
    }
    
    func asksForDismiss() {
        
        self.searchFilterVisible = false // toogle search filter
    }
    
}

//MARK: - NavigationBarViewControllerDelegate

extension SearchResultViewController: SearchResultNavigationViewDelegate {
    
    private func cleanUp() {
        self.settings = nil
    }
    
    func filterTapped() {
        self.searchFilterVisible = !self.searchFilterVisible // toogle search filter
    }
    
    func saleFilter(_ state: Bool) {
        guard let _ = self.settings else { return }
        self.settings!.onSale = state
        self.loadItems(self.settings!)
    }
    
    func queryTapped() {
        self.cleanUp()
        self.navigationController?.hero.dismissViewController()
        
    }
    
    func dismissTapped() {
        self.cleanUp()
        
        self.navigationController?.hero.dismissViewController()
    }
    
    func suggestionsTapped(suggestion: String) {
        guard
            var newSettings: ItemListSettings = self.settings,
            let query: String = self.settings?.query as? String
            else { return }
        newSettings.query = "\(query) \(suggestion)"
        
        self.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: newSettings)
    }
    
    
}
