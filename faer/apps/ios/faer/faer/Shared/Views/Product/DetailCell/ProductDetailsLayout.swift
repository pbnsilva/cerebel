import UIKit

protocol ProductDetailsLayoutDelegate: class {
    
    func sizeForItems(_ collectionView:UICollectionView) -> CGSize
    
    func itemsInCollection(_ collectionView:UICollectionView) -> Int
    
}

class ProductDetailsLayout: UICollectionViewLayout {
    //1. ProductDetails Layout Delegate
    weak var delegate: ProductDetailsLayoutDelegate?
    
    //3. Array to keep a cache of attributes.
    fileprivate var cache = [UICollectionViewLayoutAttributes]()
    
    fileprivate var contentWidth: CGFloat = 0
    
    fileprivate var itemCount: Int = 0
    
    override var collectionViewContentSize: CGSize {
        let size: CGSize = delegate?.sizeForItems(collectionView!) ?? CGSize.zero
        return CGSize(width: contentWidth, height: size.height)
    }
    
    override func prepare() {
        self.updateAttributesIfNeed()
    }
    
    private func updateAttributesIfNeed() {
        guard
            let _ = collectionView,
            collectionView!.numberOfSections > 0,
            collectionView!.numberOfItems(inSection: 0) != self.itemCount else {
            return
        }
        self.itemCount = collectionView!.numberOfItems(inSection: 0)
        cache.removeAll()
        var xOffset: CGFloat = 0
        for item in 0 ..< self.itemCount {
            
            let indexPath = IndexPath(item: item, section: 0)
            
            // 4. Asks the delegate for the height of the picture and the annotation and calculates the cell frame.
            let itemSize: CGSize = delegate?.sizeForItems(collectionView!) ?? CGSize.zero
            
            let frame = CGRect(x: xOffset, y: 0, width: itemSize.width, height: itemSize.height)
            
            // 5. Creates an UICollectionViewLayoutItem with the frame and add it to the cache
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame
            cache.append(attributes)
            
            // 6. Updates the collection view content width
            contentWidth = frame.maxX
            xOffset = xOffset + itemSize.width
            
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {

        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        self.updateAttributesIfNeed() // during prepare(), the correct number of items might not be yet available
        // Loop through the cache and look for items in the rect
        for attributes in cache {
            if attributes.frame.intersects(rect) {
                visibleLayoutAttributes.append(attributes)
            }
        }
        return visibleLayoutAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath.item]
    }
    
}
