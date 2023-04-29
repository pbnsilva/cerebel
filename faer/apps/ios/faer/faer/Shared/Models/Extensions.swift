//
//  Extensions.swift
//  faer
//
//  Created by pluto on 24.08.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView
import NotificationBannerSwift


class Tick {
    let tickTime : Date
    init () {
        tickTime = Date()
    }
    func tock (s: String) {
        let tockTime = Date()
        let executionTime = tockTime.timeIntervalSince(tickTime)
        print("[execution time] \(s): \(executionTime)")
    }
}

// MARK: Unique array
// https://stackoverflow.com/questions/25738817/removing-duplicate-elements-from-an-array/36048862#36048862
public extension Sequence where Iterator.Element: Hashable {
    
    public func unique() -> [Iterator.Element] {
        var buffer: [Iterator.Element] = []
        var lookup = Set<Iterator.Element>()
        
        for element in self {
            guard !lookup.contains(element) else { continue }
            
            buffer.append(element)
            lookup.insert(element)
        }
        
        return buffer
    }
}

// MARK: Load UIView from XIB

extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

// MARK: UIViewController

extension UIViewController {
    
    public func isVisible() -> Bool {
        return self.viewIfLoaded?.window != nil
    }
        
}

// Email Validation in UITextField

extension UITextField {
    
    func textIsValidEmail() -> Bool {
        guard let text = self.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: text)
    }

}


// MARK: URL Extension

func associatedObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    initialiser: () -> ValueType)
    -> ValueType {
        if let associated = objc_getAssociatedObject(base, key)
            as? ValueType { return associated }
        let associated = initialiser()
        objc_setAssociatedObject(base, key, associated,
                                 .OBJC_ASSOCIATION_RETAIN)
        return associated
}
func associateObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    value: ValueType) {
    objc_setAssociatedObject(base, key, value,
                             .OBJC_ASSOCIATION_RETAIN)
}

protocol PropertyStoring {
    
    associatedtype T
    
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T
}

extension PropertyStoring {
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T {
        guard let value = objc_getAssociatedObject(self, key) as? T else {
            return defaultValue
        }
        return value
    }
}

extension URL: PropertyStoring {
    
    typealias T = URL
    
    private struct CustomProperties {
        static var proxied = URL(fileURLWithPath: "")
    }
    
    var proxied: URL {
        get {
            //return self
            return getAssociatedObject(&CustomProperties.proxied, defaultValue: CustomProperties.proxied)
        }
        set {
            return objc_setAssociatedObject(self, &CustomProperties.proxied, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    init?(rawEncodedUrlStringToBeProxied: String) {
        self.init(string: rawEncodedUrlStringToBeProxied)
        self.proxied = self.usingProxy()
    }
    
    func usingProxy() -> URL {
        return self
        //TODO implement image proxy service
    }
    
}

//MARK: Other Extensions

extension UILabel {
    var isPulsating: Bool {
        get {
            guard let _ = self.layer.animationKeys(), self.layer.animationKeys()!.count > 0 else {
                return false
            }
            return true
        }
        set {
            if (newValue) {
                let animateDuration: Double = 0.8
                UIView.animate(withDuration: animateDuration, delay: 1.0, options: [.repeat, .autoreverse], animations: {
                    self.alpha = 0.2
                }, completion: nil)
                return
            }
            self.layer.removeAllAnimations()
        }
    }
}

extension UIImage {
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        
        let size = self.size
        let aspectRatio =  size.width/size.height
        
        switch contentMode {
        case .scaleAspectFit:
            if aspectRatio > 1 {                            // Landscape image
                width = dimension
                height = dimension / aspectRatio
            } else {                                        // Portrait image
                height = dimension
                width = dimension * aspectRatio
            }
            
        default:
            fatalError("UIIMage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }
        
        let renderFormat:UIGraphicsImageRendererFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }

        
        return newImage
    }
}


extension UIViewController {
    
    func alert(message: String, title: String = "") -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        return alertController
    }
    
    // adds a loading animation in the middle of the view
    func display(loadingAnimation: Bool) {
        let viewTag = 99999
        switch loadingAnimation {
        case true:
            let v = NVActivityIndicatorView(frame: self.view.bounds)
            v.tag = viewTag
            v.startAnimating()
            self.view.addSubview(v)
            v.translatesAutoresizingMaskIntoConstraints = false
            v.centerXAnchor.constraint(equalTo: v.superview!.centerXAnchor)
            v.centerYAnchor.constraint(equalTo: v.superview!.centerYAnchor)
            v.widthAnchor.constraint(equalToConstant: 50)
            v.heightAnchor.constraint(equalToConstant: 50)
        case false:
            for v in self.view.subviews {
                if v.tag == viewTag {
                    (v as! NVActivityIndicatorView).stopAnimating()
                    v.removeFromSuperview()
                }
            }
        }
    }
    
}
/*
extension UIView {
    
    func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil).first! as! UIView
        
        return view
    }
    
}
*/
