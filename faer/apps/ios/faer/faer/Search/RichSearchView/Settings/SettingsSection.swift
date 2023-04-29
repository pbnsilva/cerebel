//
//  PopularCategoriesSection.swift
//  faer
//
//  Created by pluto on 31.10.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import UIKit

class SettingsSection: RichSection {
    
    convenience init(parent: UICollectionView?) {
        
        let name: String = "Settings"
        
        self.init(
            name: name,
            cellNibName: SettingsCollectionViewCell.nibName,
            cellReuseIdentifier: SettingsCollectionViewCell.reuseIdentifier,
            parent: parent)
        
        
        self.totalItems = 1
        
    }
    
    override func segue(at indexPath: IndexPath) {
        // handle by SettingsCollectionViewCellDelegate
    }
    
    override func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell: SettingsCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.itemCell.reuseIdentifier, for: indexPath) as! SettingsCollectionViewCell
        cell.delegate = self
        return cell
    }
    
    override func sizeForItem(minimumInteritemSpacing: CGFloat = 10, maxSize: CGSize) -> CGSize {
        return self.dummyCell(targetSize: maxSize)
    }

    override func referenceHeightForSectionHeader() -> CGFloat? {
        // To be override by subclasses
        return 0
    }

    private func dummyCell(targetSize: CGSize) -> CGSize {
        let dummyCell: SettingsCollectionViewCell = (Bundle.main.loadNibNamed(SettingsCollectionViewCell.nibName, owner: self, options: nil)![0] as? SettingsCollectionViewCell)!
        return dummyCell.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
    }

}

extension SettingsSection: SettingsCollectionViewCellDelegate {
    
    func settingsTapped() {
        parent?.parentViewController?.performSegue(withIdentifier: CommonSegues.appSettings.rawValue, sender: nil)
    }
    
}
