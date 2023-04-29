//
//  PageViewController.swift
//  PageControl
//
//

import UIKit
import NVActivityIndicatorView
import Hero

class MainPageViewController: UIPageViewController {
    
    var pageControl: UIPageControl?
    
    private var isPresentingSurvey: Bool = false
    
    private static let currentPageUserDefaultsKey: String = "lastVC"
    
    private var currentPage: Pages = .firstPage() {
        didSet {
            UserDefaults.standard.set(self.currentPage.rawValue, forKey: MainPageViewController.currentPageUserDefaultsKey)
        }
    }
    
    private var pendingViewController: UIViewController?    // vc that is about to be presented; used for handling status bar style
    
    override var childForStatusBarStyle: UIViewController? {
        return pendingViewController
    }
    
    private var pagesViewControllers: [UIViewController] = MainPageViewController.presentedViewControllers()

    enum Pages : Int { // must match array indexes in pagesViewControllers
        case freshLooks = 0
        case richSearch = 1
        case likes = 2
        
        static func firstPage() -> Pages {
            return Pages.freshLooks
        }
        
        static func lastPage() -> Pages {
            return Pages.likes
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // init
      //  User.shared.onboardingStatus = .newUser // for testing
        
        if User.shared.onboardingStatus == .newUser {
            guard let onboardingVC = UIStoryboard(name: OnboardingPageViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: OnboardingPageViewController.storyboardID) as? OnboardingPageViewController else {
                fatalError()
            }
            onboardingVC.onboardingDelegate = self
            setViewControllers([onboardingVC],
                               direction: .forward,
                               animated: true,
                               completion: nil)
            
        } else {
            self.setupPages()
        }
        
        // get notified when app moves to foregground
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = self
        appDelegate.window?.makeKeyAndVisible()
        
    }
    
    @objc func appMovedToForeground() {
        // self.presentSurveyIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // init analytics
        // self.presentSurveyIfNeeded()
    }
    
    private func page(for viewController: UIViewController) -> Pages? {
        guard let index = self.pagesViewControllers.index(of: viewController) else {
            return nil
        }
        
        return Pages(rawValue: index)
    }
    
    private func viewController(for page: Pages) -> UIViewController {
        return self.pagesViewControllers[page.rawValue]
    }
    
    private static func presentedViewControllers() -> [UIViewController] {
        return [
            UIStoryboard(name: DiscoverCollectionViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: DiscoverCollectionViewController.storyboardID),
            UIStoryboard(name: RichSearchViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: RichSearchNavigationController.storyboardID),
            UIStoryboard(name: LikesViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: LikesNavigationController.storyboardID)
        ]
    }
    
    private func setupPages() {
        self.dataSource = self
        self.delegate = self
        self.currentPage = Pages(rawValue: UserDefaults.standard.integer(forKey: MainPageViewController.currentPageUserDefaultsKey)) ?? .firstPage()
        self.pendingViewController = pagesViewControllers[self.currentPage.rawValue]
        setViewControllers([self.viewController(for: self.currentPage)],
                           direction: .forward,
                           animated: true,
                           completion: nil)
        self.configurePageControl()
    }
    
    // user for app notifications
    func presentSearchResult(sender: Any) {
        guard let vc = self.viewController(for: .richSearch).children.first as? RichSearchViewController else {
            return
        }
        vc.presentQuery = sender
        self.currentPage = .richSearch
    }
    
    func presentProduct(sender: Any) {
        guard let item = sender as? Item, let vc = self.viewController(for: .likes).children.first as? LikesViewController else {
            return
        }
        vc.presentItem = item
        self.currentPage = .likes
    }
   
    // this presents a NPS survey
    private func presentSurveyIfNeeded() {
        
        struct Survey: Codable {
            let present: Bool
        }
        
        guard
            let _ = self.viewControllers,
            !self.isPresentingSurvey,
            User.shared.usageFrequency > 1, // do not show on first app usage
            self.currentPage != .richSearch
            else { return }
        
        for child in self.children { // already running survey
            if child is SurveyViewController {
                return
            }
        }
        
        self.isPresentingSurvey = true // make sure we don't run presentSurveyIfNeeded multiple times, e.g. when user is swiping fast
        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
            URLSession.shared.dataTask(with: GlobalConfig.surveyResource) { (data, response, error) in // we have survey kill switch
                guard let _ = data, let s: Survey = try? JSONDecoder().decode(Survey.self, from: data!), s.present else {
                    return
                }
                DispatchQueue.main.async {
                    SurveyViewController.show(parent: self)
                }
                }.resume()
        })
    }
    
    
    func showSearch() {
        setViewControllers([pagesViewControllers[Pages.richSearch.rawValue]],
                           direction: .forward,
                           animated: true,
                           completion: nil)
    }
    
    
    private func configurePageControl() {
        if self.pageControl == nil {
            self.pageControl = UIPageControl(frame: CGRect(x: 0,y: UIScreen.main.bounds.maxY - 50, width: UIScreen.main.bounds.width, height: 50))
            self.view.addSubview(self.pageControl!)
        }
        
        self.pageControl?.numberOfPages = self.pagesViewControllers.count
        self.pageControl?.currentPage = self.currentPage.rawValue
        self.pageControl?.tintColor = StyleGuide.colorButton
        self.pageControl?.currentPageIndicatorTintColor = StyleGuide.colorButton
        self.pageControl?.pageIndicatorTintColor = UIColor.darkText
    }
    
}

// MARK: Delegate methods
extension MainPageViewController: UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed else { return }
        guard let currentVC = pendingViewController, let currentPage = self.page(for: currentVC) else {
            fatalError()
        }
        self.currentPage = currentPage
        self.pageControl?.currentPage = self.currentPage.rawValue
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        self.pendingViewController = pendingViewControllers.first
    }
    
}

// MARK: Data source functions.
extension MainPageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard User.shared.onboardingStatus == .completed else {
            return nil
        }
        
        if let beforePage = Pages(rawValue: self.currentPage.rawValue - 1) {
            return self.viewController(for: beforePage)
        } else {
            return self.viewController(for: Pages.lastPage())
        }
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard User.shared.onboardingStatus == .completed else {
            return nil
        }
        
        
        if let nextPage = Pages(rawValue: self.currentPage.rawValue + 1) {
            return self.viewController(for: nextPage)
        } else {
            return self.viewController(for: Pages.firstPage())
        }
        
    }
    
}

extension MainPageViewController: OnboardingPageViewControllerDelegate {
    
    func completed() {
        self.setupPages()
    }
    
    
}

