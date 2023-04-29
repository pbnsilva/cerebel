//
//  LikesViewController.swift
//  faer
//
//  Created by pluto on 28.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import SquareMosaicLayout
import Hero
import SDWebImage
import UserNotifications

class LikesViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    static var storyboardName: String = "LikesViewController"
    static let storyboardID: String = "LikesViewController"
    
    private var collectionViewElements = [LikeSection]()
    private var likeSizes:[CGSize] = []
    private var likes:[Item] = []
    private let cellSpacing:CGFloat = 5
    
    weak var presentItem: Item? // used for notification
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    private var layoutCounter: CGFloat = 0
    
    private var safeAreaOffSet: CGFloat {
        get {
            if #available(iOS 11, *) {
                return max(UIApplication.shared.statusBarFrame.height, UIApplication.shared.keyWindow!.safeAreaInsets.top)
            } else {
                return 0
                // on ios 10 insets are set correctly by default, i.e. header appears under status bar
            }
        }
    }
    @IBOutlet weak var noLikesInfo: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBAction func searchTapped(_ sender: Any) {
        let parent: MainPageViewController = self.parent as! MainPageViewController
        parent.showSearch()
    }
    
    @IBAction func enableSaleBtnTapped(_ sender: Any) {
        AppNotifications.shared.authorizationStatus { (status) in
            
                switch status {
                case .notDetermined:
                    AppNotifications.shared.askForPermission(completion: { (status) in
                        if status == .authorized {
                            DispatchQueue.main.async {
                                self.enableSaleBtn.isHidden = true
                            }
                        }
                    })
                default:
                    let refreshAlert = UIAlertController(title: "Sale notifications", message: "Enable notifications and don't miss when a product goes on sale.", preferredStyle: UIAlertController.Style.alert)
                    
                    refreshAlert.addAction(UIAlertAction(title: "Open Settings", style: .default, handler: { (action: UIAlertAction!) in
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }))
                    
                    refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    }))
                    DispatchQueue.main.async {
                        self.present(refreshAlert, animated: true, completion: nil)
                    }
                }
        }
    }
    
    @IBOutlet weak var enableSaleBtn: UIButton!
    
    
    private enum LikeSectionType: String {
        case Today = "Today"
        case ThisWeek = "This Week"
        case PreviousWeek = "Last Week"
        case BeforePreviousWeek = "Some Time Ago"
    }
    
    private class LikeSection {
        var type: LikeSectionType
        var items: [Item]
        
        init(type: LikeSectionType, items: [Item]) {
            self.type = type
            self.items = items
        }
    }
    
    private func updateCollectionView() {
        
        if User.shared.likes.isEmpty {
            self.noLikesInfo.isHidden = false
            
            AppNotifications.shared.authorizationStatus { (status) in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.enableSaleBtn.isHidden = true
                    } else {
                        self.enableSaleBtn.isHidden = false
                    }
                }
            }
            
        } else {
            self.noLikesInfo.isHidden = true
        }
        
        populateLikesFromUser()
        
        self.collectionView?.reloadData()
    }
    
    private func populateLikesFromUser() {
        
        let activeLikes: [Item] = User.shared.likes.compactMap{ return $0.likedAt == nil ? nil : $0 }
        
        var sortedLikes: [Item] = activeLikes.sorted(by: {
            return $0.likedAt! > $1.likedAt!
        })
        
        let likedToday: [Item] = sortedLikes.filter{ Calendar.current.isDateInToday($0.likedAt!) }
        sortedLikes = sortedLikes.filter { !likedToday.contains($0) }

        let likedThisWeek: [Item] = sortedLikes.filter{ Calendar.current.isDateInThisWeek(date: $0.likedAt!) }
        sortedLikes = sortedLikes.filter { !likedThisWeek.contains($0) }

        let likedPreviousWeek: [Item] = sortedLikes.filter{ Calendar.current.isDateInPreviousWeek(date: $0.likedAt!) }
        sortedLikes = sortedLikes.filter { !likedPreviousWeek.contains($0) }

        let likedBeforePreviousWeek: [Item] = sortedLikes
        
        self.collectionViewElements.removeAll()
        if !likedToday.isEmpty {  self.collectionViewElements.append(LikeSection(type: .Today, items: likedToday)) }
        if !likedThisWeek.isEmpty {  self.collectionViewElements.append(LikeSection(type: .ThisWeek, items: likedThisWeek)) }
        if !likedPreviousWeek.isEmpty {  self.collectionViewElements.append(LikeSection(type: .PreviousWeek, items: likedPreviousWeek)) }
        if !likedBeforePreviousWeek.isEmpty {  self.collectionViewElements.append(LikeSection(type: .BeforePreviousWeek, items: likedBeforePreviousWeek)) }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observers to handle AppNotifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentProduct, object: nil) // handle event alerts
        NotificationCenter.default.addObserver(self, selector: #selector(self.handle(notification:)), name: .presentSearchResult, object: nil) // handle event alerts

        // detect when app get in the foreground
        NotificationCenter.default.addObserver(self, selector: #selector(movedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // preload images
        guard User.shared.likes.count > 0 else { return }
        collectionView?.prefetchDataSource = self
        
        self.setNeedsStatusBarAppearanceUpdate()

    }
    
    @objc
    private func handle(notification: NSNotification) {
        guard self.isVisible() else { return }
        
        guard let userInfo = AppNotifications.UserInfo(notification.userInfo) else { return }
        
        self.performSegue(withIdentifier: userInfo.segue.rawValue, sender: userInfo.payload)
    }
    
    @objc
    private func movedToForeground() {
        self.updateCollectionView()
    }

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.collectionView?.canCancelContentTouches = false
        if let item = self.presentItem {
            self.performSegue(withIdentifier: CommonSegues.PDP.rawValue, sender: item)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        self.updateCollectionView()
    }
  
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.presentItem = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func sectionHeading(title: String, withHeart: Bool = false) -> NSAttributedString {
        
        // attributed Title
        let textAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font : UIFont(name: StyleGuide.fontSemiBold, size: StyleGuide.fontHeadlineSize)!
        ]
        let attributedTitle: NSMutableAttributedString =  NSMutableAttributedString(string: title, attributes: textAttributes)

        if !withHeart {
            return attributedTitle
        }
        
        let heartAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.font : UIFont(name: StyleGuide.font.icon.rawValue, size: StyleGuide.fontHeadlineSize*1.1)!,
            NSAttributedString.Key.foregroundColor: StyleGuide.red
        ]
        attributedTitle.append(NSAttributedString(string: StyleGuide.icon.heart.rawValue, attributes: heartAttributes))
        return attributedTitle
        
    }
    
    // MARK: UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.collectionViewElements.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collectionViewElements[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header: LikeCollectionViewHeader = collectionView.dequeueSupplementary(LikeCollectionViewHeader.reuseIdentifier, indexPath: indexPath, kind: kind) as! LikeCollectionViewHeader
        
        // get title
        let title: NSAttributedString
        
        if indexPath.section == 0 {
            title = self.sectionHeading(title: "\(self.collectionViewElements[indexPath.section].type.rawValue) You ", withHeart: true)
        } else {
            title = self.sectionHeading(title: self.collectionViewElements[indexPath.section].type.rawValue)
        }
        
        if indexPath.section == 0 {
            header.centerY.constant = self.safeAreaOffSet / 2 // adjust start of first section to account for safe area
        }
        
        header.title.attributedText = title
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: likeCollectionViewCellReuseIdentifier, for: indexPath) as? LikeCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        //prefetch images
        let item: Item = self.collectionViewElements[indexPath.section].items[indexPath.row]
        guard let _ = item.imageURLs.first, let c = cell as? LikeCollectionViewCell else { return }
        
        c.imageView.sd_setImage(with: item.imageURLs.first!, placeholderImage: nil)
        c.hero.id = String(item.hashValue)

    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        (cell as? LikeCollectionViewCell)?.imageView?.sd_cancelCurrentImageLoad()
    }
        
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item: Item = self.collectionViewElements[indexPath.section].items[indexPath.row]
        Log.Tap.item(view: .Likes, item: item)
        self.performSegue(withIdentifier: CommonSegues.PDP.rawValue, sender: item)
        
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }
}

// MARK: UICollectionViewDataSourcePrefetching
extension LikesViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        var urls: [URL] = []
        for indexPath in indexPaths {
            guard self.likes.indices.contains(indexPath.row), let _ = self.likes[indexPath.row].imageURLs.first else { continue }
            urls.append(self.likes[indexPath.row].imageURLs.first!)
        }
        SDWebImagePrefetcher.shared.prefetchURLs(urls)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard let cell = collectionView.cellForItem(at: indexPath) else { continue }

            (cell as? LikeCollectionViewCell)?.imageView?.sd_cancelCurrentImageLoad()
        }
    }
}


extension LikesViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        if section == 0 {
            return CGSize(width: self.collectionView.bounds.width, height: LikeCollectionViewHeader.height + self.safeAreaOffSet)
        }
        
        return CGSize(width: self.collectionView.bounds.width, height: LikeCollectionViewHeader.height)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // calculate cell size
        
        let cellHorizontalSpacing: CGFloat = (self.collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.minimumLineSpacing ?? 5
        
        let side: CGFloat = UIScreen.main.bounds.width
        let width = (side / 2) - (cellHorizontalSpacing / 2)
        let height = (side / 2) * 1.5
        
        return CGSize(width: width, height: height)
       
    }
    
}


