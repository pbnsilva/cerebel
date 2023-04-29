//
//  SearchResultNavigationController.swift
//  faer
//
//  Created by pluto on 03.11.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit

class SearchResultNavigationController: UINavigationController {
    
    var navigationBarExtension: SearchResultNavigationView?
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    
    private var navigationBarExtensionHeight: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.definesPresentationContext = true
                
        self.barHideOnSwipeGestureRecognizer.addTarget(self, action: #selector(didSwipe))
        
        self.setNeedsStatusBarAppearanceUpdate()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }

    
    @objc
    func didSwipe(sender: UIPanGestureRecognizer) {
        
        guard let _ = self.navigationBarExtension else { return }

        if self.navigationBar.frame.minY > 0 {
            UIView.animate(withDuration: 0.22) {
                self.navigationBarExtension!.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: 0).isActive = true
                self.navigationBarExtension?.alpha = 1
                self.view.layoutIfNeeded()
            }
            if #available(iOS 11.0, *) {
                self.children.first?.additionalSafeAreaInsets = UIEdgeInsets(top: self.navigationBarExtension!.bounds.height, left: 0, bottom: 0, right: 0)
            } else {
                // Fallback on earlier versions
            }
        } else {
            self.navigationBarExtension?.alpha = 0
            self.view.layoutIfNeeded()
        
            if #available(iOS 11.0, *) {
                self.children.first?.additionalSafeAreaInsets = UIEdgeInsets()
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    override func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        super.setNavigationBarHidden(hidden, animated: animated)
        UIView.animate(withDuration: 0.01) {
            self.navigationBarExtension?.isHidden = hidden
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func dummyCell(targetSize: CGSize) -> CGSize {
        let dummyCell: SettingsCollectionViewCell = (Bundle.main.loadNibNamed(SettingsCollectionViewCell.nibName, owner: self, options: nil)![0] as? SettingsCollectionViewCell)!
        return dummyCell.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }
    
    private func sizeForNavigationExtension(tags: [String]) -> CGSize {
        // calculate size depending on whether there are guided tags
        let dummyView: SearchResultNavigationView = SearchResultNavigationView.fromNib()
        dummyView.configure(tags: tags, settings: nil)
        return dummyView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }

    func configureNavigationBar(tags: [String], settings: ItemListSettings?) {
        
        let fittingSize: CGSize = self.sizeForNavigationExtension(tags: tags)

        guard self.navigationBarExtension == nil else {
            navigationBarExtensionHeight?.constant = fittingSize.height
            navigationBarExtension?.configure(tags: tags, settings: settings)
            navigationBarExtension?.setNeedsLayout()
            navigationBarExtension?.layoutSubviews()
            return
        }
        
        // create view
        self.navigationBarExtension = SearchResultNavigationView.fromNib()
        self.view.addSubview(navigationBarExtension!)
        navigationBarExtension?.translatesAutoresizingMaskIntoConstraints = false
        navigationBarExtension?.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0).isActive = true
        navigationBarExtension?.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0).isActive = true
        navigationBarExtension?.topAnchor.constraint(equalTo: self.navigationBar.bottomAnchor, constant: 0).isActive = true
        navigationBarExtensionHeight = navigationBarExtension?.heightAnchor.constraint(equalToConstant: fittingSize.height)
        navigationBarExtensionHeight?.isActive = true
        
        
        navigationBarExtension?.configure(tags: tags, settings: settings)
        // update insets
        if #available(iOS 11.0, *) {
            self.children.first?.additionalSafeAreaInsets = UIEdgeInsets(top: self.navigationBarExtension!.bounds.height, left: 0, bottom: 0, right: 0)
        } else {
            // Fallback on earlier versions
        }
        
        if settings?.onSale == true {
            self.navigationBarExtension?.salesIcon.isHidden = false
        }
        
    }

}


extension SearchResultNavigationController: UIGestureRecognizerDelegate {
   /*
     make the swipeBar less sensitive to appear when scrolling left / right in search result
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // fail pan on swipe down in filter view
        if gestureRecognizer is UIPanGestureRecognizer &&
            otherGestureRecognizer is UISwipeGestureRecognizer,
            let navigationBar = self.navigationBarExtension,
            navigationBar.isHidden {
            return true
        }

        return false
    }
    */
}
