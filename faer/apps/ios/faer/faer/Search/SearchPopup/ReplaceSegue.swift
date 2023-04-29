//
//  ReplaceSegue.swift
//  faer
//
//  Created by pluto on 30.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import UIKit

/*
 
 This segue is only used for the SearchPopup VC. We won't replace the SearchPop with the new SearchResult, but allow the user to go back to VC that triggered the SearchPop in the first place using back button.
 
*/

class ReplaceSegue: UIStoryboardSegue {
    override func perform() {
        //super.perform()
        source.navigationController!.hero.replaceViewController(with: destination)
        
        // source.hero.replaceViewController(with: destination)
        // source.navigationController?.setViewControllers([destination], animated: true)
    }
}
