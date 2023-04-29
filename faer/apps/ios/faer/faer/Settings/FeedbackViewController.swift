//
//  FeedbackViewController.swift
//  faer
//
//  Created by pluto on 15.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import Hero

class FeedbackViewController: UIViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }

    
    private weak var commentText: UITextView?
    
    private weak var submitBtn: UIButton?
    
    private weak var emailText: UITextField?
    
    private var defaultCommentCopy: String?
    
    @IBAction func returnBtnTapped(_ sender: Any) {
        self.emailText?.resignFirstResponder()
    }
    
    @IBAction func backBtnTapped(_ sender: UIBarButtonItem) {
        self.hero.dismissViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.submitBtn = self.view.viewWithTag(6) as? UIButton
        self.submitBtn?.addTarget(self, action: #selector(submitBtnTapped), for: .touchUpInside)
        
        self.commentText = self.view.viewWithTag(5) as? UITextView
        self.emailText = self.view.viewWithTag(7) as? UITextField
        
        //        self.commentText?.textContainerInset = UIEdgeInsets.zero
        //      self.commentText?.textContainer.lineFragmentPadding = 0
        
        self.commentText?.delegate = self
        self.defaultCommentCopy = self.commentText?.text
        
        self.commentText?.layer.borderWidth = 1
        self.commentText?.layer.borderColor = UIColor.groupTableViewBackground.cgColor
        self.commentText?.layer.cornerRadius = 5
        
        self.setNeedsStatusBarAppearanceUpdate()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }

    
    @objc
    private func submitBtnTapped(sender: UIButton) {
        if let _ = self.commentText, self.commentText!.text != "" {
            Log.Event.feedback(email: self.emailText?.text ?? "", text: self.commentText?.text ?? "")
        }
        self.commentText?.resignFirstResponder()
        self.emailText?.resignFirstResponder()
        self.hero.dismissViewController()
    }
    
    func setupTextFieldsAccessoryView(_ textView: UITextView) {
        guard textView.inputAccessoryView == nil else {
//            print("textfields accessory view already set up")
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
        let doneButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(didPressDoneButton))
        doneButton.tintColor = .white
        
        // Note, that we declared the `didPressDoneButton` to be called, when Done button has been pressed
        toolBar.items = [flexsibleSpace, doneButton]
        
        // Assing toolbar as inputAccessoryView
        self.commentText?.inputAccessoryView = toolBar
        
    }
    
    @objc
    func didPressDoneButton(button: UIButton) {
        self.commentText?.resignFirstResponder()
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

extension FeedbackViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        self.setupTextFieldsAccessoryView(textView)
        if self.commentText?.text == self.defaultCommentCopy {
            self.commentText?.text = ""
        }
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if self.commentText?.text == "" {
            self.commentText?.text = self.defaultCommentCopy
        }
    }
    
}
