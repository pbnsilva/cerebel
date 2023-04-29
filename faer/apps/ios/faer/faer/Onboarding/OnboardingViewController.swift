//
//  OnboardingViewController.swift
//  faer
//
//  Created by pluto on 10.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

/*
 
 Dummy class that must be subclassed by viewcontrollers in the onboarding flow
 
 Every instance must set the delegate to notify the OnboardingPageViewController when the step is completed
 
 */

import Foundation
import UIKit

protocol OnboardingViewControllerDelegate :class {
    func stepCompleted(viewController: UIViewController)
}


class OnboardingViewController: UIViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    weak var onboardingDelegate: OnboardingViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
}
