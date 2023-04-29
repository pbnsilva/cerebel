/*
 Based on   
 iwheelbuy@gmail.com
 */
import UIKit
import SquareMosaicLayout

protocol DiscoverLayoutDelegate :class {
    func collectionView(_ collectionView: UICollectionView,
                        referenceHeightForHeaderInSection section: Int) -> CGFloat
    func collectionView(_ collectionView: UICollectionView,
                        referenceHeightForFooterInSection section: Int) -> CGFloat
}

final class DiscoverLayout: SquareMosaicLayout, SquareMosaicDataSource {
    
    weak var discoverDelegate: DiscoverLayoutDelegate?
    
    convenience init() {
        self.init(direction: SquareMosaicDirection.vertical)
        self.dataSource = self
    }
    
    func layoutPattern(for section: Int) -> SquareMosaicPattern {
        return DiscoverLayoutPattern()
    }
    
    func layoutSupplementaryHeader(for section: Int) -> SquareMosaicSupplementary? {
        
        let height: CGFloat = self.discoverDelegate?.collectionView(self.collectionView!, referenceHeightForHeaderInSection: section) ?? DiscoverCollectionHeaderReusableView.height
        return VerticalHeaderSupplementary(height: height)
    }
    
    func layoutSupplementaryFooter(for section: Int) -> SquareMosaicSupplementary? {

        let height: CGFloat = self.discoverDelegate?.collectionView(self.collectionView!, referenceHeightForFooterInSection: section) ?? DiscoverCollectionFooterReusableView.height
        return VerticalFooterSupplementary(height: height)
    }
    
}

class VerticalHeaderSupplementary: SquareMosaicSupplementary {
    
    private var safeAreaOffSet: CGFloat {
        get {
            if #available(iOS 11, *) {
                return max(UIApplication.shared.statusBarFrame.height, UIApplication.shared.keyWindow!.safeAreaInsets.top)
            } else {
                return UIApplication.shared.statusBarFrame.height
            }
        }
    }
    
    private var topInset: CGFloat = 2
    
    private var height: CGFloat
    
    init(height: CGFloat) {
        self.height = height
    }
    
    func supplementaryFrame(for origin: CGFloat, side: CGFloat) -> CGRect {
        return CGRect(x: 0, y: safeAreaOffSet - topInset, width: side, height: self.height)
    }
    
    func supplementaryHiddenForEmptySection() -> Bool {
        return true
    }
}

class VerticalFooterSupplementary: SquareMosaicSupplementary {
    
    private var height: CGFloat
    
    init(height: CGFloat) {
        self.height = height
    }
    
    func supplementaryFrame(for origin: CGFloat, side: CGFloat) -> CGRect {
        return CGRect(x: 0, y: origin, width: side, height: self.height)
    }
    
    func supplementaryHiddenForEmptySection() -> Bool {
        return true
    }
}


class DiscoverLayoutPattern: SquareMosaicPattern {
    
    func patternBlocks() -> [SquareMosaicBlock] {
        return [
            DiscoverLayoutBlock1(),
            DiscoverLayoutBlock2()
        ]
    }
    
    func patternBlocksSeparator(at position: SquareMosaicBlockSeparatorPosition) -> CGFloat {
        let cellSpacing:CGFloat = 2.0
        return cellSpacing
    }
}

public class DiscoverLayoutBlock1: SquareMosaicBlock {
    
    public func blockFrames() -> Int {
        return 3
    }
    
    public func blockFrames(origin: CGFloat, side: CGFloat) -> [CGRect] {
        let cellSpacing:CGFloat = 2.0
        let minWidth = side / 3.0
        let maxWidth = side - minWidth
        let minHeight = minWidth * 1.5
        let maxHeight = minHeight + minHeight
        var frames = [CGRect]()
        frames.append(CGRect(x: 0, y: origin, width: maxWidth - cellSpacing, height: maxHeight - cellSpacing))
        frames.append(CGRect(x: maxWidth, y: origin, width: minWidth, height: minHeight - cellSpacing))
        frames.append(CGRect(x: maxWidth, y: origin + minHeight, width: minWidth, height: minHeight - cellSpacing))
        return frames
    }
}

public class DiscoverLayoutBlock2: SquareMosaicBlock {
    
    public func blockFrames() -> Int {
        return 3
    }
    
    public func blockFrames(origin: CGFloat, side: CGFloat) -> [CGRect] {
        let cellSpacing:CGFloat = 2.0
        let minWidth = side / 3.0
        let maxWidth = side - minWidth
        let minHeight = minWidth * 1.5
        let maxHeight = minHeight + minHeight
        var frames = [CGRect]()
        frames.append(CGRect(x: 0, y: origin, width: minWidth, height: minHeight - cellSpacing))
        frames.append(CGRect(x: 0, y: origin + minHeight, width: minWidth, height: minHeight - cellSpacing))
        frames.append(CGRect(x: minWidth + cellSpacing, y: origin, width: maxWidth, height: maxHeight - cellSpacing))
        return frames
    }
}
