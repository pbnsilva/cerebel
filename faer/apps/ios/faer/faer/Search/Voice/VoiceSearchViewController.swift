//
//  VoiceSearchViewController.swift
//  faer
//
//  Created by pluto on 04.11.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import FirebaseAnalytics
import Hero
import AVFoundation
import NVActivityIndicatorView

class VoiceSearchViewController: SearchInputTypeViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .default
    }
    
    @IBOutlet weak var micHint: UILabel!
    @IBOutlet weak var transcriptView: UILabel!
    @IBOutlet weak var speakHintView: UIView!
    @IBOutlet weak var inputAnimation: NVActivityIndicatorView!
    
    @IBOutlet weak var speakHintTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var micBtnHint: UIView!
    @IBOutlet weak var micButton: MicButton!
    
    @IBOutlet weak var greeting: UILabel!
    private var greetingText: String {
        get {
            let hour: Int = Calendar.current.component(.hour, from: Date())
            if hour > 0, hour < 12 {
                return "Good morning,\nhow can I help?"
            }
            if hour > 12, hour < 17 {
                return "Good afternoon,\nhow can I help?"
            }
            if hour > 17, hour < 20  {
                return "Good evening,\nhow can I help?"
            }
            return "Hello,\nhow can I help?"
        }
    }
    @IBOutlet weak var questionHint1: UILabel!
    @IBOutlet weak var questionHint2: UILabel!
    @IBOutlet weak var questionHint3: UILabel!
    
    private var speechInterface: VoiceSearchInterface?
    
    private let defaultTranscriptHint: String = "Speak now..."
    private var defaultSpeakHintTopConstant: CGFloat!
    
    private var player: AVAudioPlayer? // must be class member
    private var lastSearch: Date?
    
    private let totalSearchesDefaultsKey: String = "totalSearches"
    private var totalSearches: Int = 0 {
        didSet {
            guard self.totalSearches > 0 else { return }
            UserDefaults.standard.set(self.totalSearches, forKey: totalSearchesDefaultsKey)
        }
    }
    
    private var animationDelay: TimeInterval = 2 // Seconds
    private var showAnimations: Bool {
        get {
            guard self.isVisible() else {
                return false
            }
            guard let _ = lastSearch else {
                return true
            }
            guard Date().timeIntervalSince(lastSearch!) < 1440 else { // don't search hints if search within last 24 hours
                return false
            }
            return false
        }
    
    }
    
    private var hideMicHintState: Bool {
        get {
            if self.totalSearches > 0 {
                return true
            }
            return false
        }
        
    }

    
    private var hasPermissions: Bool {
        get {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                if self.speechInterface == nil {
                    self.speechInterface = VoiceSearchInterface()
                    self.speechInterface?.delegate = self
                }
                return true
            default:
                return false
            }
        }
    }
    
    private var transcriptInProgress: Bool = false
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Handle changes in the search input type
        self.addEventListner(for: .keyboard)
        self.addEventListner(for: .camera)
                
        self.defaultSpeakHintTopConstant = self.speakHintTopConstraint.constant
        
        self.inputAutoActivate = false
        
        self.micButton.delegate = self
        
        self.totalSearches = UserDefaults.standard.integer(forKey: self.totalSearchesDefaultsKey)
        
        self.inputAnimation.color = StyleGuide.red
        
        self.setNeedsStatusBarAppearanceUpdate()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.greeting.text = self.greetingText
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.micButton.isEnabled = true
        
        if self.showAnimations {
            self.perform(#selector(showQuestionHints), with: nil, afterDelay: self.animationDelay)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.restoreInitialViewState()
        self.inputAnimation.stopAnimating()
 //       self.stopListining()
        self.micButton.isTapped = false
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopListining()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.restoreInitialViewState()
    }
    
    override func applicationEnteredForeground() {
        super.applicationEnteredForeground()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }

    
    // MARK: Handle audio permissions

    private func requestPermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            OperationQueue.main.addOperation {
                AVAudioSession.sharedInstance().requestRecordPermission { (authStatus) in
                }
            }
        case .denied:
            self.openSettings(title: "Turn on voice search", message: "Tap Settings to let Faer use your microphone")
        case .granted:
            return
        }

    }
    
    // MARK: Voice interface control
    
    private func startListining() {
        self.greeting.isHidden = true
        self.micBtnHint.isHidden = true
        self.hideQuestionHints()
        self.transcriptView.isHidden = false
        
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if self.showAnimations {
            self.perform(#selector(showQuestionHints), with: nil, afterDelay: self.animationDelay)
        }
        
        DispatchQueue.global(qos: .default).async {
            self.speechInterface?.startAudio()
        }
    }
    
    private func stopListining() {
        DispatchQueue.global(qos: .default).async {
            self.speechInterface?.stopAudio()
        }
    }
    
    // MARK: Handle search
    
    // remove stopwords from search query
    private func cleanUpQuery(_ q: String) -> String {
        var tmp: String = q
        tmp = tmp.replacingOccurrences(of: "Find me a", with: "", options: .caseInsensitive, range: nil)
        tmp = tmp.replacingOccurrences(of: "Find me", with: "", options: .caseInsensitive, range: nil)
        tmp = tmp.replacingOccurrences(of: "I'm looking for", with: "", options: .caseInsensitive, range: nil)
        tmp = tmp.replacingOccurrences(of: "looking for", with: "", options: .caseInsensitive, range: nil)
        return tmp
    }
    
    private func performSearchIfNeeded() {
        // do we have user input or transcribed text?
        guard let query: String = self.transcriptView.text, !query.isEmpty, query != self.defaultTranscriptHint else {
            restoreInitialViewState()
            return
        }
        // stop if interaction still going on, user pressing or transcription
        guard
            !self.transcriptInProgress,
            !self.micButton.isPressed
        else { return }
        self.micButton.isTapped = false
        Log.Tap.search(self.cleanUpQuery(query))
        self.performSegue(withIdentifier: CommonSegues.searchResult.rawValue, sender: self.cleanUpQuery(query))
        // self.delegate?.requestSearch(sender: self, query: self.cleanUpQuery(query)) use for old 3 button design
        self.totalSearches += 1
        self.lastSearch = Date()
    }
    
    //MARK: - Handle animations
    
    override func transitionForSearching(visible: Bool) {
        // disable record button while search is in progress
        switch visible {
        case true:
            return
        case false:
            self.inputAnimation.stopAnimating()
        }
        self.micButton.isEnabled = !visible
    }

    private func restoreInitialViewState() {
        self.transcriptView.text = self.defaultTranscriptHint
        self.transcriptView.isHidden = true
        self.micBtnHint.isHidden = self.hideMicHintState
        self.speakHintView.isHidden = true
        self.greeting.isHidden = false
    }

    @objc
    private func showQuestionHints(invokeAfter: TimeInterval = 0) {
       // guard self.hasPermissions else { return }
        self.setQuestionHintsForGender()
        self.view.layoutIfNeeded()
        self.speakHintTopConstraint.constant = self.defaultSpeakHintTopConstant - (self.speakHintView.bounds.height / 0.3)
        self.speakHintView.alpha = 0.0
        self.speakHintView.isHidden = false
        UIView.animate(withDuration: 0.6, delay: invokeAfter, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.speakHintView.alpha = 1
            self.transcriptView.alpha = 0
           // self.micBtnHint.alpha = 0
            self.speakHintTopConstraint.constant = self.defaultSpeakHintTopConstant
        }, completion: { (done) in
            //self.perform(#selector(self.hideQuestionHints), with: nil, afterDelay: self.animationDelay)
        })
    }
    
    @objc
    private func hideQuestionHints() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        UIView.animate(withDuration: 0.6, delay: 0, options: .curveLinear, animations: {
            self.speakHintView.alpha = 0
            self.transcriptView.alpha = 1
            self.micBtnHint.alpha = 1
        }, completion: { (done) in
            self.speakHintView.isHidden = true
        //    self.greeting.isHidden = true
        })
    }
    
    private func setQuestionHintsForGender() {
        switch User.shared.gender {
        case .all:
            self.questionHint1.text = "Find me a black dress"
            self.questionHint2.text = "Find me a pair of jeans"
            self.questionHint3.text = "Find me a blue sweater"
        case .female:
            self.questionHint1.text = "Find me a black summer dress"
            self.questionHint2.text = "Find me a pair of jeans"
            self.questionHint3.text = "Find me a blue sweater"
        case .male:
            self.questionHint1.text = "Find me a pair of black jeans"
            self.questionHint2.text = "Find me a pair of sneakers"
            self.questionHint3.text = "Find me a blue sweater"
        case .unknown:
            self.questionHint1.text = "Find me a black summer dress"
            self.questionHint2.text = "Find me a blue sweater"
            self.questionHint3.text = "Find me a pair of jeans"
        }
    }


}

//MARK: - MicButtonDelegate

extension VoiceSearchViewController: MicButtonDelegate {
    
    func becameActive() {
        guard self.hasPermissions else {
            self.requestPermissions()
            // wait for micbutton animation to finish before dismissing it, otherwise UI looks weird
            DispatchQueue.main.asyncAfter(deadline: .now() + self.micButton.animationDuration, execute: {
                self.micButton.isTapped = false
            })
            
            return
        }

        guard Network.shared.isReachable() else {
            BannerNotification.noInternetConnection()
            self.micButton.isTapped = false
            return
        }

        self.startListining()
    }
    
    func resignedActive() {
        self.stopListining()
        self.performSearchIfNeeded()
    }
}


//MARK: - VoiceSearchInterfaceDelegate

extension VoiceSearchViewController: VoiceSearchInterfaceDelegate {
    func received(intermediateText: String) {
        self.hideQuestionHints()
        self.transcriptView.text = intermediateText
        self.transcriptInProgress = true
        self.inputAnimation.startAnimating()
    }
    
    func received(finalText: String) {
        self.transcriptView.text = finalText
        self.transcriptInProgress = false
        self.performSearchIfNeeded()
    }
    
    func streamingInterrupted(error: Error) {
        //TODO
    }

}



