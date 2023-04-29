
import UIKit

protocol OnboardingPageViewControllerDelegate :class {
    func completed()
}

class OnboardingPageViewController: UIPageViewController {
    
    static let storyboardName: String = "Onboard"
    
    static let storyboardID: String = "OnboardingPageViewControllerSB"
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    weak var onboardingDelegate: OnboardingPageViewControllerDelegate?

    private lazy var currentPage: Int = 0
    
    private var pages: [OnboardingViewController] = {
        return [
            UIStoryboard(name: OnboardingPageViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: GenderViewController.storyboardID) as! GenderViewController,
            UIStoryboard(name: OnboardingPageViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: NewsletterViewController.storyboardID) as! NewsletterViewController,

            //UIStoryboard(name: LoginViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: LoginViewController.storyboardID) as! LoginViewController
        ]
    }()
    
    fileprivate func getViewController(withIdentifier identifier: String) -> UIViewController
    {
        return UIStoryboard(name: OnboardingPageViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier: identifier)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.setNeedsStatusBarAppearanceUpdate()
        
        self.update()
    }
    
    private func update() {
        // transitions to the currentPage
        self.setViewControllers([pages[currentPage]], direction: .forward, animated: true, completion: nil)
        self.pages[currentPage].onboardingDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
}

extension OnboardingPageViewController: OnboardingViewControllerDelegate {
    
    func stepCompleted(viewController: UIViewController) {
        self.currentPage += 1
        guard self.currentPage < self.pages.count else {
            User.shared.onboardingStatus = .completed
            User.shared.save()
            Log.Event.onboardingEnd()
            self.onboardingDelegate?.completed()
            return
        }
        self.update()
    }
    
}
