//
//  ItemWebViewController.swift
//  faer
//
//  Created by pluto on 15.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import WebKit
import NVActivityIndicatorView
import FirebaseAnalytics
import Hero

class ItemWebViewController: UIViewController, WKNavigationDelegate {
    
    static let storyboardID: String = "webViewSB"
    static let storyboardName: String = "ItemWebView"
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    let transitionManager = ItemWebViewTransition()
    
    @IBOutlet weak var progressBarView: UIProgressView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var webContainer: UIView!
    
    @IBOutlet weak var shareBtn: UIButton!
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        
        guard let _ = self.item else { return }
        
        let activityViewController = UIActivityViewController(
            activityItems: [self.item!.shareUrl],
            applicationActivities: nil)
        // required to prevent crash on ipad
        let dummyBarButton = UIBarButtonItem(customView: self.shareBtn)
        
        activityViewController.popoverPresentationController?.barButtonItem = dummyBarButton
        
        activityViewController.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, activityError) in
            guard completed, let _ = self, let _ = self?.item else { return }
            let itemParameters: [String: Any] = Log.serialize(self!.item!) // pass by value to avoid retention cycle in AV completion closure
            Log.Tap.share(view: .Shop, parameters: itemParameters)
        }
        
        self.present(activityViewController, animated: true, completion: nil)
        
    }
    
    @IBOutlet weak var loadingView: UIStackView!
    
    var webView: WKWebView?
    var item: Item!
    
    private var panGR = UIPanGestureRecognizer()
    private var checkOutStarted: Bool = false
    
    private enum Segues: String {
        case toProductDetail = "itemWebPDPSegue"
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
        // setting up in viewWillAppear and loadView or viewDidLoad as container frame is not available otherwise
        // setup constrains

        webView = WKWebView()
        webView?.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A356 Safari/604.1" // Safari 11 on iOS 11
        webView?.backgroundColor = .clear
        self.webContainer?.insertSubview(webView!, at: 0)
        webView?.translatesAutoresizingMaskIntoConstraints = false
        webView?.topAnchor.constraint(equalTo: webView!.superview!.topAnchor).isActive = true
        webView?.leadingAnchor.constraint(equalTo: webView!.superview!.leadingAnchor).isActive = true
        webView?.trailingAnchor.constraint(equalTo: webView!.superview!.trailingAnchor).isActive = true
        webView?.bottomAnchor.constraint(equalTo: webView!.superview!.bottomAnchor).isActive = true
        webView?.isHidden = true
        
        // configure
        webView?.navigationDelegate = self
        let urlRequest = URLRequest(url: item.url)
        webView!.load(urlRequest)
        webView?.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView?.addObserver(self, forKeyPath: #keyPath(WKWebView.loading), options: .new, context: nil)
        
        self.titleLabel?.text = "Loading..."
        self.urlLabel?.text = item.url.absoluteString
        self.loadingView?.isHidden = false
        
        self.setNeedsStatusBarAppearanceUpdate()

     }
    
    deinit {
        self.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        self.webView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.loading))
        NotificationCenter.default.removeObserver(self, name: .presentProduct, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Log.View.shop(item: item)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // MARK: - WKUIDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url?.absoluteURL, !self.checkOutStarted else {
            return
        }
        if url.absoluteString.lowercased().range(of: "checkout") != nil || url.absoluteString.lowercased().range(of: "checkouts") != nil {
            Log.View.checkoutBegin(self.item)
            self.checkOutStarted = true // prevent firing checkout events for every new page view in the checkout process
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // Display Progress Bar While Loading Pages
        if keyPath == "loading" {
            if webView!.isLoading {
                progressBarView.isHidden = false
            } else {
                progressBarView.isHidden = true
            }
        }
        if keyPath == "estimatedProgress" {
            progressBarView.progress = Float(webView!.estimatedProgress)
            if webView!.estimatedProgress >= 0.5 {
                webContainer?.alpha = 1
                webView?.alpha = 1
                self.titleLabel.text = self.item.name
                webView?.isHidden = false
            }
        }
    }

}
