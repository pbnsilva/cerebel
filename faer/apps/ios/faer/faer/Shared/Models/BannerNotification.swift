//
//  Notification.swift
//  faer
//
//  Created by pluto on 07.11.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import NotificationBannerSwift

class BannerNotification: NSObject {
    
    var title: String!
    
    class Colors: BannerColorsProtocol {
        
        public func color(for style: BannerStyle) -> UIColor {
            switch style {
            case .danger:   return UIColor(red:1.00, green:1.00, blue:1.00, alpha:0.8)
            case .info:     return UIColor(red:1, green:1, blue:1, alpha:0.8)
            case .none:     return UIColor.clear
            case .success:  return UIColor(red:0, green:0, blue:0, alpha:0.8)
            case .warning:  return UIColor(red:0, green:0, blue:0, alpha:0.8)
            }
        }
    }
    
    static func warning(title: String, autoDismiss: Bool = true) {
        let titleAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font : UIFont(name: StyleGuide.fontSemiBold, size: 12)!
        ]
        DispatchQueue.main.async {
            let banner: StatusBarNotificationBanner = StatusBarNotificationBanner(
                attributedTitle: NSAttributedString(string: title, attributes: titleAttributes),
                style: .warning,
                colors: BannerNotification.Colors()
            )
            banner.autoDismiss = autoDismiss
            banner.onSwipeUp = { banner.dismiss() }
            banner.show()
        }
    }
    
    static func noInternetConnection() {
        
        guard NotificationBannerQueue.default.numberOfBanners == 0 else { // make sure there are no other banners displaying
            return
        }
        
        let titleAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font : UIFont(name: StyleGuide.fontSemiBold, size: 12)!
        ]
        DispatchQueue.main.async {
            let banner: StatusBarNotificationBanner = StatusBarNotificationBanner(
                attributedTitle: NSAttributedString(string: Messages.noInternet, attributes: titleAttributes),
                style: .warning,
                colors: BannerNotification.Colors()
            )
            banner.autoDismiss = true
            banner.onSwipeUp = { banner.dismiss() }
            banner.show()
        }

        
    }

}

extension NotificationBanner {
    
    convenience init(title: String, subtitle: String, url: URL) {
        let titleAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.darkText,
            NSAttributedString.Key.font : UIFont(name: StyleGuide.fontSemiBold, size: 18)!
        ]
        let subtitleAttributes:[NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.darkText,
            NSAttributedString.Key.font : UIFont(name: StyleGuide.fontSemiBold, size: 14)!
        ]
        self.init(
            attributedTitle: NSAttributedString(string: title, attributes: titleAttributes),
            attributedSubtitle: NSAttributedString(string: subtitle, attributes: subtitleAttributes),
            leftView: nil,
            rightView: nil,
            style: .info,
            colors: BannerNotification.Colors()
        )
        
        self.autoDismiss = false
        self.onSwipeUp = { self.dismiss() }
    }
    
}
