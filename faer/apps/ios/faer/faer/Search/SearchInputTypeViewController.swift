//
//  SearchTypeViewController.swift
//  faer
//
//  Created by pluto on 17.02.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit
import Hero

protocol SearchInputTypeDelegate :class {
    func changeSearchInputType(requested: SearchInputType)
    func requestSearch(sender: SearchInputTypeViewController, query: Any)
    func requestItemWeb(item: Item)
}

enum SearchInputType: Int {
    // tags must be set in IB view tag accordingly
    case microphone = 1
    case keyboard = 2
    case camera = 3
}

class SearchInputTypeViewController: UIViewController {
    
    weak var delegate: SearchInputTypeDelegate?
    
    var requiresFullScreen: Bool = false
    
    var previousInputType: SearchInputType! // 
    
    private var micBtn: UIButton?
    private var cameraBtn: UIButton?
    private var keyboardBtn: UIButton?
    
    public var inputAutoActivate: Bool = true // immediliate active input when view becomes visible

    override var disablesAutomaticKeyboardDismissal: Bool {
        get { return true } // or false
        set { }
    } 

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.hero.isEnabled = true
        // ini menu buttons
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationEnteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    public func addEventListner(for searchInput: SearchInputType) {
        switch searchInput {
        case .microphone:
            self.keyboardBtn = self.view.viewWithTag(SearchInputType.microphone.rawValue) as? UIButton
            self.keyboardBtn?.addTarget(self, action: #selector(inputButtonTapped(_:)), for: .touchUpInside)
            self.keyboardBtn?.hero.modifiers = [.arc]
        case .keyboard:
            self.keyboardBtn = self.view.viewWithTag(SearchInputType.keyboard.rawValue) as? UIButton
            self.keyboardBtn?.addTarget(self, action: #selector(inputButtonTapped(_:)), for: .touchUpInside)
            self.keyboardBtn?.hero.modifiers = [.arc]
        case .camera:
            self.cameraBtn = self.view.viewWithTag(SearchInputType.camera.rawValue) as? UIButton
            self.cameraBtn?.addTarget(self, action: #selector(inputButtonTapped(_:)), for: .touchUpInside)
            self.cameraBtn?.hero.modifiers = [.arc]
        }
    }
    
    @objc public func applicationEnteredForeground() {
        
    }
    
    func updatedQuery(value: Any) {
        // To be overrided when subclassing
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc public func inputButtonTapped(_ sender: UIButton) {
        self.delegate?.changeSearchInputType(requested: SearchInputType(rawValue: sender.tag)!)
    }
    
    func openSettings(title: String, message: String) {
        let alertController: UIAlertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        
        let settingsAction: UIAlertAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    //print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alertController.addAction(settingsAction)

        self.present(alertController, animated: true, completion: nil)

    }
    
    // Subclasses can override this for custom UI during transition
    func transitionForSearching(visible: Bool) {
        // dummy implementation
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
