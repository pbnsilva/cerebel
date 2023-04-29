//
//  GenderViewController.swift
//  faer
//
//  Created by venus on 27.10.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit

class GenderViewController: OnboardingViewController {
    
    static let storyboardID: String = "genderSB"
    
    @IBAction func shopWomenTapped(_ sender: Any) {
        User.shared.gender = .female
        self.onboardingDelegate?.stepCompleted(viewController: self)
    }
    
    @IBAction func shopMenTapped(_ sender: Any) {
        User.shared.gender = .male
        self.onboardingDelegate?.stepCompleted(viewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Log.Event.onboardingBegin()
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
