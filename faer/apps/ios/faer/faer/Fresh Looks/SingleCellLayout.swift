/*
 Based on
 iwheelbuy@gmail.com
 */
import UIKit
import SquareMosaicLayout


final class SingleCellLayout: SquareMosaicLayout, SquareMosaicDataSource {
    
    weak var discoverDelegate: DiscoverLayoutDelegate?
    
    convenience init() {
        self.init(direction: SquareMosaicDirection.vertical)
        self.dataSource = self
    }
    
    func layoutPattern(for section: Int) -> SquareMosaicPattern {
        return SingleCellLayoutPattern()
    }
    
    func layoutSupplementaryHeader(for section: Int) -> SquareMosaicSupplementary? {
        
        let height: CGFloat = self.discoverDelegate?.collectionView(self.collectionView!, referenceHeightForHeaderInSection: section) ?? DiscoverCollectionHeaderReusableView.height
        return VerticalHeaderSupplementary(height: height)
    }
    
    func layoutSupplementaryFooter(for section: Int) -> SquareMosaicSupplementary? {
        
        return VerticalFooterSupplementary(height: 0)
    }
    
}

final class SingleCellLayoutSupplementary: SquareMosaicSupplementary {
    
    static let supplementaryHeight: CGFloat = DiscoverCollectionHeaderReusableView.height
    
    func supplementaryFrame(for origin: CGFloat, side: CGFloat) -> CGRect {
        return CGRect(x: 0, y: origin, width: side, height: SingleCellLayoutSupplementary.supplementaryHeight)
    }
}


class SingleCellLayoutPattern: SquareMosaicPattern {
    
    func patternBlocks() -> [SquareMosaicBlock] {
        return [
            SingleCellLayoutBlock()
        ]
    }
    
    func patternBlocksSeparator(at position: SquareMosaicBlockSeparatorPosition) -> CGFloat {
        return 0
    }
}

public class SingleCellLayoutBlock: SquareMosaicBlock {
    
    public func blockFrames() -> Int {
        return 1
    }
    
    public func blockFrames(origin: CGFloat, side: CGFloat) -> [CGRect] {
        var frames = [CGRect]()
        let maxHeight: CGFloat = UIScreen.main.bounds.height - SingleCellLayoutSupplementary.supplementaryHeight - 50 // account for status bar height

        frames.append(CGRect(x: 0, y: origin, width: side, height: maxHeight))
        return frames
    }
}

