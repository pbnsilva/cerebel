//
//  Segues.swift
//  faer
//
//  Created by pluto on 18.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import UIKit

enum CommonSegues: String {
    case PDP = "PDPSegue"
    case searchResult = "searchResultSegue"
    case map = "mapSegue"
    case webView = "webViewSegue"
    case searchPopup = "searchPopupSegue"
    case visualSearch = "visualSearchSegue"
    case appSettings = "appSettingsSegue"
    case brandProfile = "brandProfileSegue"
}

class CommonSeguesManager {
    
    static func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let _ = segue.identifier, let targetSegue: CommonSegues = CommonSegues(rawValue: segue.identifier!) else { return }
        
        switch targetSegue {
        case .appSettings:
            // no preparation necessary
            break;
            
        case .visualSearch:
            // no preparation necessary
            break;
        case .searchPopup:
            guard
                let vc = (segue.destination as! UINavigationController).viewControllers.first as? SearchPopupViewController
                else { return }
            
            vc.configure(settings: sender as? ItemListSettings)
            
        case .searchResult:
            guard
                let vc = (segue.destination as! SearchResultNavigationController).viewControllers.first as? SearchResultViewController,
                let _ = sender
                else { return }
                        
            vc.configure(query: sender!)
        case .PDP:
            guard
                let _ = segue.destination as? ProductDetailNavigationController,
                let vc: ProductDetailCollectionViewController = (segue.destination as! ProductDetailNavigationController).topViewController! as? ProductDetailCollectionViewController,
                let _ = sender as? Item
                else { return }
            
            vc.configure(item: (sender as! Item))
        case .map:
            guard
                let nc = segue.destination as? UINavigationController,
                let vc = nc.viewControllers.first as? MapViewController
                else { return }
            vc.stores = sender as? [Store]
        case .webView:
            guard
                let nc = segue.destination as? UINavigationController,
                let vc = nc.viewControllers.first as? ItemWebViewController,
                let _ = sender as? Item
            else { return }
            vc.item = sender as? Item
        case .brandProfile:
            guard
                let nc = segue.destination as? UINavigationController,
                let vc = nc.viewControllers.first as? BrandProfileCollectionViewController,
                let _ = sender as? Item
                else { return }
            vc.item = sender as? Item
        }
    }
}
