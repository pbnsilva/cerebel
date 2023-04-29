//
//  VoiceSearchNavigationViewController.swift
//  faer
//
//  Created by pluto on 12.11.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class VoiceSearchNavigationViewController: UINavigationController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
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
