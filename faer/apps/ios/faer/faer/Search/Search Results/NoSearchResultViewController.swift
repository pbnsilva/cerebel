//
//  NoSearchResultViewController.swift
//  faer
//
//  Created by pluto on 22.09.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import Hero

class NoSearchResultViewController: SearchInputTypeViewController {
    
    static let storyboardIdentifier = "noSearchResultSB"
    
    private var panGR = UIPanGestureRecognizer()
    
    private let queryNeedle: String = "<query>"
    
    var list: ItemList?

    var query: Any?
    
   // image query
    @IBOutlet weak var imageContainer: UIView!
    
    // text query
    @IBOutlet weak var textContainer: UIView!
    @IBOutlet weak var textText: UILabel!
    @IBOutlet weak var textAction: UIButton!
    @IBAction func textActionTapped(_ sender: Any) {
        self.delegate?.requestSearch(sender: self, query: self.list!.similar!.query)
    }
    
    // error query
    @IBOutlet weak var errorContainer: UIView!
    
    // unknown text query
    @IBOutlet weak var unknownTextContainer: UIView!
    @IBOutlet weak var unknownText: UILabel!
    
    @IBAction func dismissbtnTapped(_ sender: Any) {
        self.delegate?.changeSearchInputType(requested: self.previousInputType)
    }
    
    @IBOutlet weak var dismissBtnTapped: FaerButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hero.modalAnimationType = .selectBy(presenting: .fade, dismissing: .fade)
        
        self.textAction.titleLabel!.numberOfLines = 2
        self.textAction.titleLabel!.textAlignment = .center
        
        // swip to dismiss
        panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gestureRecognizer:)))
        view.addGestureRecognizer(panGR)
        
        self.configureView()

    }
    
    private func configureView() {
        
        guard !(self.query is UIImage) else {
            /* self.textContainer.isHidden = false
             self.textText.text = "Sorry, your photo didn't match any products."*/
            self.imageContainer.isHidden = false
            return
        }
        
        guard let _ = query as? String else {
            self.unknownTextContainer.isHidden = false
            self.unknownText.text = "Sorry, your search didn't match any products."
            return
        }
        
        let quotedQuery: String = "\"\(self.query! as! String)\""
        
        guard let _ = self.list?.queryAnnotations else {
            self.unknownTextContainer.isHidden = false
            self.unknownText.text = self.unknownText.text!.replacingOccurrences(of: self.queryNeedle, with: quotedQuery)

            return
        }
        
        self.textContainer.isHidden = false
        self.textText.text = self.textText.text?.replacingOccurrences(of: self.queryNeedle, with: quotedQuery)

        if let _ = self.list?.similar {
            self.textAction.isHidden = false
            let newBtnTitle: String = self.textAction.currentTitle!.replacingOccurrences(of: self.queryNeedle, with: self.list!.similar!.query)
            self.textAction.setTitle(newBtnTitle, for: .normal)
        }

    }


    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handlePan(gestureRecognizer:UIPanGestureRecognizer) {
        switch panGR.state {
        case .began:
            // begin the transition as normal
            self.delegate?.changeSearchInputType(requested: self.previousInputType)
        case .changed:
            // calculate the progress based on how far the user moved
            let translation = panGR.translation(in: nil)
            let progress = translation.y / 2 / view.bounds.height
            Hero.shared.update(progress)
            
        default:
            // end the transition when user ended their touch
            Hero.shared.finish()
        }
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
