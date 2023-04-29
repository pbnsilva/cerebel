//
//  SearchPopupNavigationController.swift
//  faer
//
//  Created by pluto on 27.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SearchPopupNavigationController: UINavigationController {
    
    static let storyboardID: String = "SearchPopupNavigationController"
    
    override var childForStatusBarStyle: UIViewController? {
        return SearchPopupViewController.fromStoryboard()
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setNeedsStatusBarAppearanceUpdate()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
