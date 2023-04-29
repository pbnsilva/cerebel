//
//  NewsletterViewController.swift
//  faer
//
//  Created by pluto on 11.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class NewsletterViewController: OnboardingViewController {
    
    static let storyboardID: String = "newsletterSB"

    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var emailAddressInvalidLabel: UILabel!
    
    @IBOutlet weak var stepCompletedBtn: UIButton!
    
    @IBAction func stepCompletedBtnTapped(_ sender: Any) {
        
        self.onboardingDelegate?.stepCompleted(viewController: self)
        
    }
    @IBAction func subscribeBtnTapped(_ sender: Any) {
        if let trimmedEmail = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmedEmail.isEmpty {
            Log.Event.newsletterSubscribed(email: trimmedEmail)
        }
        self.onboardingDelegate?.stepCompleted(viewController: self)
    }
    
    @IBOutlet weak var subscribeBtn: UIButton!
    
    
    @IBAction func emailFieldDidBeginEditing(_ sender: Any) {
        self.setupTextFieldsAccessoryView()
    }
    
    @IBAction func emailFieldDidEndEditing(_ sender: Any) {
    }
    
    @IBAction func emailFieldPrimaryAction(_ sender: Any) {
        
        guard let textField = sender as? UITextField else { return }
    
        if let _ = textField.text, textField.text!.isEmpty {
            self.emailTextField.textColor = .lightGray
            self.emailTextField.text = "Your email address"
            emailTextField.resignFirstResponder()
            return
        }
        
        if textField.textIsValidEmail() {
            self.emailAddressInvalidLabel.isHidden = true
            self.stepCompletedBtn.isHidden = true
            self.subscribeBtn.isHidden = false
            emailTextField.resignFirstResponder()
        } else {
            self.stepCompletedBtn.isHidden = false
            self.subscribeBtn.isHidden = true
            self.emailAddressInvalidLabel.isHidden = false
        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.stepCompletedBtn.isHidden = false
        self.subscribeBtn.isHidden = true
    }
    
    func setupTextFieldsAccessoryView() {
        guard emailTextField.inputAccessoryView == nil else {
            return
        }
        
        // Create toolBar
        let toolBar: UIToolbar = UIToolbar(frame:CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
        toolBar.barStyle = UIBarStyle.black
        toolBar.isTranslucent = true
        
        // Add buttons as `UIBarButtonItem` to toolbar
        // First add some space to the left hand side, so your button is not on the edge of the screen
        let flexsibleSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil) // flexible space to add left end side
        
        // Create your first visible button
        let cancelButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.cancel, target: self, action: #selector(didPressCancelButton))
        cancelButton.tintColor = .white
        cancelButton.style = .done // make it bold
        // Note, that we declared the `didPressDoneButton` to be called, when Done button has been pressed
        toolBar.items = [flexsibleSpace, cancelButton]
        
        // Assing toolbar as inputAccessoryView
        emailTextField.inputAccessoryView = toolBar
    }
    
    @objc
    func didPressCancelButton(button: UIButton) {
        emailAddressInvalidLabel.isHidden = true
        emailTextField.text = nil
        emailTextField.resignFirstResponder()
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
