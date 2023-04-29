//
//  SurveyViewController.swift
//  faer
//
//  Created by pluto on 07.08.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class SurveyViewController: UIViewController {
    
    static let storyboardName: String = "SurveyView"
    
    private static let completedDefaultsKey: String = "SurveyViewControllerCompleted"
    
    private static let runningDefaultsKey: String = "SurveyViewControllerRunning"
    
    lazy var presentingFromSettings: Bool = false
    @IBOutlet weak var startTitle: UILabel!
    
    @IBOutlet weak var startInfo: UILabel!
    
    static public func show(parent: UIViewController) {
        
        if SurveyViewController.isCompleted {
            return
        }

        let child: SurveyViewController = UIStoryboard(name: SurveyViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier :"SurveyView") as! SurveyViewController
        parent.addChild(child)
        
        // Add child VC's view to parent
        parent.view.addSubview(child.view)
        
        // Setup constraints for layout
        child.view.translatesAutoresizingMaskIntoConstraints = false
        
        child.view.topAnchor.constraint(equalTo: parent.view.topAnchor).isActive = true
        child.view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor).isActive = true
        
        child.view.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor).isActive = true
        child.view.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor).isActive = true
        
        // Register child VC
        child.didMove(toParent: parent)
    }
    
    static var isCompleted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: SurveyViewController.completedDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SurveyViewController.completedDefaultsKey)
        }
    }

    
    static public func fromStoryboard() -> SurveyViewController {
        return UIStoryboard(name: SurveyViewController.storyboardName, bundle: nil).instantiateViewController(withIdentifier :"SurveyView") as! SurveyViewController
    }
    
    
    @IBAction func startBtnTapped(_ sender: Any) {
        self.startView.isHidden = true
        self.npsView.isHidden = false
        Log.Survey.began()
    }
    
    @IBOutlet weak var npsContinueBtn: UIButton!
    
    @IBAction func npsContinueBtnTapped(_ sender: Any) {
        self.npsView.isHidden = true
        self.commentView.isHidden = false
        self.commentText.becomeFirstResponder()
    }
    
    @IBAction func skipBtnTapped(_ sender: Any) {
        
        SurveyViewController.isCompleted = true
        
        if !endView.isHidden {
            Log.Survey.completed()
        } else {
            Log.Survey.cancelled()
        }
        
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
        
    }
    
    
    /* Last View */
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var emailFieldWarning: UILabel!
    @IBOutlet weak var emailFieldInfo: UILabel!
    
    @IBAction func emailFieldStartedEditing(_ sender: Any) {
        // Implement if needed
        self.emailField.textColor = .darkText
    }
    
    @IBAction func emailFieldDidEndEditing(_ sender: Any) {
        // Implement if needed
    }
    
    @IBAction func emailFieldPrimaryAction(_ sender: Any) {
        
        if let _ = emailField.text, emailField.text!.isEmpty {
            self.emailField.textColor = .lightGray
            self.emailField.text = "Your email address"
            self.emailFieldWarning.isHidden = true
            emailField.resignFirstResponder()
            return
        }
        
        if emailField.textIsValidEmail() {
            emailField.resignFirstResponder()
            self.emailFieldWarning.isHidden = true
            Log.Survey.email(email: emailField.text!)
            self.skipBtnTapped(sender)
        } else {
            self.emailField.textColor = .red
            self.emailFieldWarning.isHidden = false
        }
        
    }
    
    @IBAction func commentContinue(_ sender: Any) {
        self.commentView.isHidden = true
        self.endView.isHidden = false
        if !commentText.text.isEmpty {
            Log.Survey.comment(text: commentText.text)
        }
    }
    
    @IBOutlet weak var translucentBackground: UIView!
    
    @IBOutlet weak var containerView: UIView!
    
    private var npsPicker: UIPickerView!
    
    private var commentText: UITextView!
    
    // MARKUP: Survey pages start
    
    @IBOutlet weak var npsView: UIView!
    
    @IBOutlet weak var startView: UIView!
    
    @IBOutlet weak var commentView: UIView!
    
    @IBOutlet weak var endView: UIView!
    
    // MARKUP: Survey pages end
    
    private var commentPlaceholder: String!
    
    private var keyboardHeight: CGFloat = 0
    
    private let npsPickerDataSource: [String] = ["Please select a value", "0 - Not likely", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10 - Extremely likely"]
    
    @IBOutlet weak var commentActionsBottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // configure container view
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true
        
        //configure rest
        self.npsPicker = self.view.viewWithTag(5) as? UIPickerView
        
        self.commentText = self.view.viewWithTag(6) as? UITextView
        self.commentText?.textColor = .lightGray
        self.commentPlaceholder = self.commentText.text
        self.commentText.textContainerInset = UIEdgeInsets.zero
        self.commentText.textContainer.lineFragmentPadding = 0
        
        self.emailFieldInfo.font = UIFont(name: StyleGuide.fontBody, size: self.emailFieldInfo.font!.pointSize) // IB bug: Manuall set font, as open Sans is not recognized properly when using attributedText

        let startInfo: UILabel = self.view.viewWithTag(8) as! UILabel
        startInfo.font = UIFont(name: StyleGuide.fontBody, size: startInfo.font!.pointSize)
        
        // for getting keyboard height
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc
    private func keyboardWillShow(notification: NSNotification) {
    /*    guard
            let keyboardSize: CGRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            else { return }
        
        self.commentActionsBottom.constant = self.commentActionsBottom.constant + keyboardSize.height
        self.keyboardHeight = keyboardSize.height*/
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
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

extension SurveyViewController: UIPickerViewDelegate {
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        return self.makePickerLabel(reuseView: view, row: row, text: self.npsPickerDataSource[row])
        
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row > 0 {
            Log.Survey.npsRating(score: row - 1)
            self.npsContinueBtn.isEnabled = true
            
        } else {
            self.npsContinueBtn.isEnabled = false
        }
        
    }
    
}


extension SurveyViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return npsPickerDataSource.count
    }
    
    private func makePickerLabel(reuseView: UIView?, row: Int, text: String) -> UIView {
        
        let fontName: String
        if row == 0 {
            fontName =  StyleGuide.fontRegular
        } else {
            fontName = StyleGuide.fontSemiBold
        }
        
        let pickerLabel: UILabel = reuseView == nil ? UILabel() : (reuseView as! UILabel) // reuse label
        let myAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.darkText,
            NSAttributedString.Key.font : UIFont(name: fontName, size: 18)!
        ]
        
        pickerLabel.textAlignment = .center
        pickerLabel.attributedText = NSAttributedString(string: text, attributes: myAttributes)
        return pickerLabel
    }
    
}

extension SurveyViewController: UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        setupTextFieldsAccessoryView()
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.darkText
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = self.commentPlaceholder
            textView.textColor = UIColor.lightGray
        }
    }
    
    func setupTextFieldsAccessoryView() {
        guard commentText.inputAccessoryView == nil else {
            print("textfields accessory view already set up")
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
        commentText.inputAccessoryView = toolBar
    }

    @objc
    func didPressDoneButton(button: UIButton) {
        // Button has been pressed
        // Process the containment of the textfield or whatever
        
        // Hide keyboard
        commentText.resignFirstResponder()
    }

    @objc
    func didPressCancelButton(button: UIButton) {
        // Button has been pressed
        // Process the containment of the textfield or whatever
        
        // Dismiss view
        self.skipBtnTapped(button)
    }

}
