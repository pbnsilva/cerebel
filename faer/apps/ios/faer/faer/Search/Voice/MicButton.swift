//
//  MicButton.swift
//  faer
//
//  Created by pluto on 04.11.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import UIKit
import AVFoundation
import NVActivityIndicatorView

protocol MicButtonDelegate {
    func becameActive()
    func resignedActive()
}

class MicButton: UIButton {
    
    public let animationDuration: TimeInterval = 0.7
    
    lazy private(set) var isPressed: Bool = false // indicates whether the user is holding the button
    public var isTapped: Bool = false {
        willSet(newValue) {
            guard newValue != isTapped else { return }
            switch (newValue) {
            case true:
                self.isTapped = true
                self.playSound()
                UIView.animate(withDuration: self.animationDuration, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.9, options: .curveEaseIn, animations: {
                    self.backgroundColor? = StyleGuide.red
                    self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                })
                
                return
            case false:
                self.isTapped = false
                
                UIView.animate(withDuration: self.animationDuration, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.9, options: .curveEaseOut, animations: {
                    self.transform = CGAffineTransform.identity
                    self.backgroundColor? = .darkText
                })
                return
            }
        }
    }

    public var delegate: MicButtonDelegate?
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.layer.cornerRadius = 40 //TODO make IBDesignable without crashes
        
        let longGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MicButton.longTap(_:)))
        longGesture.minimumPressDuration = 0.2
        self.addGestureRecognizer(longGesture)
        
        self.addTarget(self, action: #selector(MicButton.tapped(_:)), for: .touchUpInside)
    }
    
    private func playSound() {
        DispatchQueue.global(qos: .background).async {
            AudioServicesPlaySystemSound(SystemSoundID(1110))
        }
    }
    
    @objc
    private func longTap(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard Network.shared.isReachable() else {
            BannerNotification.noInternetConnection()
            return
        }
        guard !self.isTapped else { return }
        switch gestureRecognizer.state {
        case .began:
            self.isPressed = true
            self.delegate?.becameActive()
            
            self.playSound()
            UIView.animate(withDuration: self.animationDuration, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.9, options: .curveEaseIn, animations: {
                self.backgroundColor? = StyleGuide.red
                self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            })
            return
        case .ended:
            self.isPressed = false
            UIView.animate(withDuration: self.animationDuration, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.9, options: .curveEaseOut, animations: {
                self.transform = CGAffineTransform.identity
                self.backgroundColor? = .darkText
            })
            
            self.delegate?.resignedActive()

            return
        default:
            return
        }
    }
    
    @objc
    private func tapped(_ sender: UIButton) {
        guard Network.shared.isReachable() else {
            BannerNotification.noInternetConnection()
            return
        }
        self.isTapped = !self.isTapped
        switch (self.isTapped) {
        case true:
            self.delegate?.becameActive()
        case false:
            self.delegate?.resignedActive()
        }

    }
    
}
