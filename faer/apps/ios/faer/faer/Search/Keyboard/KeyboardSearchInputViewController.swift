//
//  KeyboardSearchInputViewController.swift
//  faer
//
//  Created by pluto on 22.02.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

class KeyboardSearchInputViewController: SearchInputTypeViewController {
    
    @IBOutlet weak var searchTypeMenuBottomConstrain: NSLayoutConstraint!
    
    @IBOutlet weak var searchHint: UILabel!
    @IBOutlet weak var textInput: UITextField!
    @IBOutlet weak var clearBtn: FaerButton!
    @IBAction func clearBtnTapped(_ sender: Any) {
        if self.clearBtn.isSelected {
            self.textInput.text = ""
            self.autocompleteVC?.clear()
            self.clearBtn.isSelected = false
        } else {
            self.inputAutoActivate = false
            self.textInput.resignFirstResponder()
            self.searchHint.isHidden = false
            self.clearBtn.isHidden = true
        }
    }
    
    @IBAction func textFieldDismissArea(_ sender: Any) {
        self.autocompleteVC?.clear()
        self.textInput.resignFirstResponder()
        self.searchHint.isHidden = false
        self.clearBtn.isHidden = true
        self.textInput.text = ""
    }
    
    private var defaultSearchTypeBottomConstrainConstant: CGFloat!
    private var isPerformingSearch: Bool = false
    
    private var autocompleteVC: SearchAutocompleteTableViewController!
    private var autocompleteViewHeight: NSLayoutConstraint!
    
    override func inputButtonTapped(_ sender: UIButton) {
        super.inputButtonTapped(sender)
        guard sender.tag == SearchInputType.camera.rawValue else {
            return
        }

        if self.textInput.isFirstResponder {
            self.textInput.text = ""
            self.inputAutoActivate = false
            self.textInput.resignFirstResponder()
            self.searchHint.isHidden = false
            self.clearBtn.isHidden = true
            self.textInput.resignFirstResponder()
        } else {
            self.textInput.becomeFirstResponder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.addEventListner(for: .microphone)
        self.addEventListner(for: .camera)
        
        self.defaultSearchTypeBottomConstrainConstant = self.searchTypeMenuBottomConstrain.constant
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.keyboardNotification(notification:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        
        self.displayAutocomplete()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(0), execute: { // https://stackoverflow.com/questions/27098097/becomefirstresponder-not-working-in-ios-8
            guard self.isVisible(), self.inputAutoActivate else { return } // additional check with isVisible as didAppear might be called twice
            self.textInput.becomeFirstResponder()
        })
        
        self.isPerformingSearch = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.autocompleteVC?.update(for: "")
    }
    
    // from https://stackoverflow.com/questions/25693130/move-textfield-when-keyboard-appears-swift
    @objc func keyboardNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            guard let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
            let bottomMargin: CGFloat = 20
            let duration:TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIView.AnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIView.AnimationOptions = UIView.AnimationOptions(rawValue: animationCurveRaw)
            if endFrame.origin.y >= UIScreen.main.bounds.size.height {
                self.searchTypeMenuBottomConstrain?.constant = self.defaultSearchTypeBottomConstrainConstant
            } else {
                self.searchTypeMenuBottomConstrain?.constant = endFrame.size.height + bottomMargin
            }
            UIView.animate(withDuration: duration,
                           delay: TimeInterval(0),
                           options: animationCurve,
                           animations: { self.view.layoutIfNeeded() },
                           completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.hideAutocomplete()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func transitionForSearching(visible: Bool) {
        if !visible {
            self.isPerformingSearch = false
            self.autocompleteVC?.clear()
        }
    }
    
    // update query if it was updated outside the scope of the VC, e.g. search filter in search result
    override func updatedQuery(value: Any) {
        guard let _ = value as? String else { return }
        self.textInput.text = value as? String
    }
    
    private func displayAutocomplete() {
        
        // Create child VC
        
        self.autocompleteVC = UIStoryboard(name: SearchAutocompleteTableViewController.storyboardName, bundle: nil).instantiateInitialViewController() as? SearchAutocompleteTableViewController
        autocompleteVC.delegate = self
        
        // Set child VC
        self.addChild(autocompleteVC)
        
        // Add child VC's view to parent
        self.view.addSubview(autocompleteVC.view)
        
        // Register child VC
        autocompleteVC.didMove(toParent: self)
        
        // Setup constraints for layout
        autocompleteVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        
        autocompleteVC.view.topAnchor.constraint(equalTo: self.textInput.bottomAnchor, constant: 20).isActive = true
     //   autocompleteVC.view.widthAnchor.constraint(equalTo: self.textInput.widthAnchor, constant: 0).isActive = true
        autocompleteVC.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 20).isActive = true
        autocompleteVC.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -40).isActive = true

        autocompleteViewHeight = autocompleteVC.view.heightAnchor.constraint(equalToConstant: autocompleteVC.tableView.contentSize.height)
        autocompleteViewHeight.isActive = true
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        guard container.preferredContentSize.height > 0 else { return }
        switch container {
        case is SearchAutocompleteTableViewController:
            self.autocompleteViewHeight?.constant = container.preferredContentSize.height // update container height when child tableview resizes
            self.autocompleteVC.tableView.layoutSubviews()
            break
        default:
            break;
        }
    }
    
    private func hideAutocomplete() {
        autocompleteVC?.willMove(toParent: nil)
        autocompleteVC?.view.removeFromSuperview()
        autocompleteVC?.removeFromParent()
    }
    
    @IBAction func textFielddidChange(_ sender: Any) {
        guard let _ = sender as? UITextField, let text: String =  (sender as! UITextField).text else { return }
        
        self.autocompleteVC?.update(for: text)
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

// MARK: - UITextViewDelegate
extension KeyboardSearchInputViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.clearBtn.isHidden = false
        self.searchHint.isHidden = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.clearBtn.isSelected = true
        
        if (string == "\n") {
            self.textInput.resignFirstResponder()
            
            // show search result
            if let query: String = textInput.text, query != "" {
                
                if query == "resetfaer" {
                    
                    User.shared.resetAllData()
                    
                }
                
                self.delegate?.requestSearch(sender: self, query: query)
                self.isPerformingSearch = true
            } else {
                self.inputAutoActivate = false
                self.clearBtn.isHidden = true
                self.clearBtn.isSelected = false
                self.searchHint.isHidden = false
            }
        }
        return true
    }
    
}

// MARK: - SearchAutocompleteTableViewController Delegate
extension KeyboardSearchInputViewController: SearchAutocompleteTableViewControllerDelegate {
    func didSelect(text: String) {
        self.textInput.text = text
        self.textInput.resignFirstResponder()

        self.delegate?.requestSearch(sender: self, query: text)
        self.isPerformingSearch = true
    }
}
