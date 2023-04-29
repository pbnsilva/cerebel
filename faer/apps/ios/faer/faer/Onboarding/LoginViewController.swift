//
//  LoginViewController.swift
//  faer
//
//  Created by venus on 10.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import FacebookLogin
import FacebookCore

class LoginViewController: OnboardingViewController {
    
    static let storyboardName: String = "Login"
    
    static let storyboardID: String = "loginSB"

    @IBAction func fbLoginBtn(_ sender: Any) {

        let loginManager = LoginManager()
        
        loginManager.logIn(readPermissions: [ .publicProfile, .email ], viewController: self) { (loginResult) in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                print("Logged in!")
                User.shared.needsUpdate()
            }
            self.onboardingDelegate?.stepCompleted(viewController: self)
        }
    }
    
    @IBAction func skipBtn(_ sender: Any) {
        self.onboardingDelegate?.stepCompleted(viewController: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
