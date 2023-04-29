//
//  ProductDetailNavigationView.swift
//  faer
//
//  Created by pluto on 28.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class ProductDetailNavigationController: UINavigationController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.hidesBarsOnSwipe = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
