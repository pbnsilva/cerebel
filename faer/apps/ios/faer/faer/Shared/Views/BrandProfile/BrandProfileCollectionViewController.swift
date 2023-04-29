//
//  BrandProfileCollectionViewController.swift
//  faer
//
//  Created by pluto on 01.02.19.
//  Copyright © 2019 pluto. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class BrandProfileCollectionViewController: UIViewController {
    
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    internal enum Sections: String, CaseIterable {
        case header
        case criteria = "Ethics and Sustainability"
        case popularProducts = "Most Popular Products"
        case category
    }
    
    typealias Section = (title: String, data: [Any])
    
    private lazy var dataSource: [Section] = []
    
    private lazy var categoriesOfBrand: [String] = []
    
    private lazy var cellSizeCache: [IndexPath: UICollectionViewCell] = [:] // cache for cell sizes
    
    private var brand: Brand!
    
    weak var item: Item?
    
    private var showLoadingIndicator: Bool = false {
        didSet {
            if self.showLoadingIndicator {
                DispatchQueue.main.async {
                    self.loadingIndicator.startAnimating()
                    self.loadingIndicator.isHidden = false
                }
            } else {
                DispatchQueue.main.async {
                    self.loadingIndicator.stopAnimating()
                    self.loadingIndicator.isHidden = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.registerCells()
                
        // Do any additional setup after loading the view.
      //  self.brandId = "35149df0e9f650b550b04668cce5bfdf75c2d50b"
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.prepareDataSource()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.showLoadingIndicator = false
    }
    
    private func prepareDataSource() {
        
        guard let _ = self.item else {
            return
        }
        
        self.showLoadingIndicator = true
        
        if self.item?.brandId != nil && !self.item!.brandId.isEmpty {
            self.loadBrand(brandId: self.item!.brandId)
        } else {
            if let _ = self.item?.brand {
                Brand.id(for: self.item!.brand) { [weak self] (brandId, error) in
                    guard error == nil, let _ = brandId else { return }
                    self?.loadBrand(brandId: brandId!)
                }
            }
        }

    }
    
    private func loadBrand(brandId: String) {
        Brand.load(brandId: brandId) { [weak self] (brand, error) in
            self?.showLoadingIndicator = false
            
            guard error == nil, let _ = brand else {
                return
            }
            
            self?.brand = brand
            self?.categoriesOfBrand = Array(brand!.categories.keys)
            
            DispatchQueue.main.async {
                self?.configureView()
                
            }
        }
    }
    
    // MARK: Controler Setup
    
    private func configureView() {
        
        guard
            let _ = self.brand,
            self.dataSource.isEmpty
        else {
            return
        }
        
        self.dataSource = [(Sections.header.rawValue, [""])] // one dummy cell
        
        if let _ = self.brand.tags {
            self.dataSource.append((Sections.criteria.rawValue, self.brand.tags!))
        }
        
        if !self.brand.popularProducts.isEmpty {
            self.dataSource.append((Sections.popularProducts.rawValue, self.brand.popularProducts))
        }

        if !self.brand.categories.isEmpty {
            for (category, items) in self.brand.categories {
                self.dataSource.append((category, items))
            }
        }

        self.collectionView?.reloadData()
    }
    
    private func registerCells() {
        self.collectionView?.register(UINib(nibName: BrandHeaderCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: BrandHeaderCollectionViewCell.reuseIdentifier)
        
        self.collectionView?.register(UINib(nibName: BrandPopularProductsCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: BrandPopularProductsCollectionViewCell.reuseIdentifier)
                
        self.collectionView?.register(UINib(nibName: BrandCriteriaCollectionViewCell.nibName, bundle: nil), forCellWithReuseIdentifier: BrandCriteriaCollectionViewCell.reuseIdentifier)

    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        CommonSeguesManager.prepare(for: segue, sender: sender)
    }

}

extension BrandProfileCollectionViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        // return size
        switch self.dataSource[indexPath.section].title {
        case Sections.criteria.rawValue, Sections.header.rawValue:
            let cell = self.getDummyCell(collectionView: collectionView, for: indexPath)
            let targetSize: CGSize = CGSize(width: UIScreen.main.bounds.width - 10, height: 50)
            let size = cell.contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            return size
        default:
            let width: CGFloat = (UIScreen.main.bounds.width - 10)
            let height: CGFloat = UIScreen.main.bounds.height * 0.5
            return CGSize(width: width, height: height)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let _ = brand, self.dataSource[section].title != Sections.header.rawValue else {
            return CGSize.zero
        }
        
        return CGSize(width: collectionView.bounds.width, height: 60)
        
    }
    
}
// MARK: UICollectionViewDataSource

extension BrandProfileCollectionViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }

    
}


extension BrandProfileCollectionViewController: UICollectionViewDataSource {
    
    @objc
    private func criteriaDiscloseBtnTapped(sender: UIButton) {
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: "criteriaDisclosurePopupVC") else { return }
        
        popVC.modalPresentationStyle = .popover

        let popOverVC = popVC.popoverPresentationController
        popOverVC?.delegate = self
        popOverVC?.backgroundColor = .black
        popOverVC?.sourceView = sender
        popOverVC?.sourceRect = CGRect(x: sender.bounds.midX, y: sender.bounds.minY, width: 0, height: 0)
        
        // replace brand placeholder in info text with brand name
        let info: UILabel? = popVC.view.viewWithTag(1) as? UILabel
        info?.text = info?.text?.replacingOccurrences(of: "<brand>", with: self.brand.name)
        
        // show info popup
        self.present(popVC, animated: false)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header: BrandProfileCollectionHeaderView = collectionView.dequeueSupplementary(BrandProfileCollectionHeaderView.reuseIdentifer, indexPath: indexPath, kind: kind) as! BrandProfileCollectionHeaderView 
        
        header.configure(title: self.dataSource[indexPath.section].title.capitalized)
        
        if self.dataSource[indexPath.section].title == Sections.criteria.rawValue {
            header.detailDisclosureBtn.isHidden = false
            header.detailDisclosureBtn.addTarget(self, action: #selector(criteriaDiscloseBtnTapped), for: .touchUpInside)
        } else {
            header.detailDisclosureBtn.isHidden = true
        }
        
        return header
        
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.dataSource.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if self.dataSource[section].title == Sections.criteria.rawValue {
            return self.dataSource[section].data.count
        }
        
        return 1
    }
    
    private func icon(for tag: String) -> UIImage? {
        
        guard let name = Brand.tagIcons[tag.lowercased()] else {
            return nil
        }
        
        return UIImage(named: name)
        
    }
    
    // self-sizing collection view: calculate cell size with auto layout
    private func getDummyCell(collectionView: UICollectionView, for indexPath: IndexPath) -> UICollectionViewCell {
        
        guard self.cellSizeCache[indexPath] == nil else {
            return self.cellSizeCache[indexPath]!
        }
        
        switch self.dataSource[indexPath.section].title {
        case Sections.header.rawValue:
            let cell: BrandHeaderCollectionViewCell = (Bundle.main.loadNibNamed(BrandHeaderCollectionViewCell.nibName, owner: self, options: nil)![0] as? BrandHeaderCollectionViewCell)!
            cell.configure(brand: self.brand)
            self.cellSizeCache[indexPath] = cell
            return cell
        case Sections.criteria.rawValue:
            let cell: BrandCriteriaCollectionViewCell = (Bundle.main.loadNibNamed(BrandCriteriaCollectionViewCell.nibName, owner: self, options: nil)![0] as? BrandCriteriaCollectionViewCell)!
            
            if let tag = self.brand.tags?[indexPath.row].capitalized {
                cell.title.text = tag
                cell.icon.image = self.icon(for: tag)
            }
            self.cellSizeCache[indexPath] = cell
            return cell
        case Sections.popularProducts.rawValue:
            let cell: BrandPopularProductsCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandPopularProductsCollectionViewCell.reuseIdentifier, for: indexPath) as! BrandPopularProductsCollectionViewCell
            cell.configure(items: self.brand.popularProducts)
            self.cellSizeCache[indexPath] = cell
            return cell
        default:
            let cell: BrandPopularProductsCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandPopularProductsCollectionViewCell.reuseIdentifier, for: indexPath) as! BrandPopularProductsCollectionViewCell
            cell.configure(items: self.brand.categories[self.dataSource[indexPath.section].title]!)
            self.cellSizeCache[indexPath] = cell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
       switch self.dataSource[indexPath.section].title {
        case Sections.header.rawValue:
            let cell: BrandHeaderCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandHeaderCollectionViewCell.reuseIdentifier, for: indexPath) as! BrandHeaderCollectionViewCell
            cell.configure(brand: self.brand)
            return cell
        case Sections.criteria.rawValue:
            let cell: BrandCriteriaCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandCriteriaCollectionViewCell.reuseIdentifier, for: indexPath) as! BrandCriteriaCollectionViewCell
            if let tag = self.brand.tags?[indexPath.row].capitalized {
                cell.title.text = tag
                cell.icon.image = self.icon(for: tag)
            }

            return cell
        case Sections.popularProducts.rawValue:
            let cell: BrandPopularProductsCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandPopularProductsCollectionViewCell.reuseIdentifier, for: indexPath) as! BrandPopularProductsCollectionViewCell
            cell.configure(items: self.brand.popularProducts)
            cell.delegate = self
            return cell
        default:
            let cell: BrandPopularProductsCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: BrandPopularProductsCollectionViewCell.reuseIdentifier, for: indexPath) as! BrandPopularProductsCollectionViewCell
            cell.configure(items: self.brand.categories[self.dataSource[indexPath.section].title]!)
            cell.delegate = self
            return cell
        }
        
    }

    
}

extension BrandProfileCollectionViewController: BrandPopularProductsCollectionViewCellDelegate {
    
    func tapped(item: Item) {
        
        
        self.performSegue(withIdentifier: CommonSegues.PDP.rawValue, sender: item)
        
        Log.Tap.item(view: .Feed, item: item)
        
    }
    
    func share(item: Item) {
        let activityViewController = UIActivityViewController(
            activityItems: [item.shareUrl],
            applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.popoverPresentationController?.sourceRect = self.view.bounds
        
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            guard completed else { return }
            let itemParameters: [String: Any] = Log.serialize(item) // pass by value to avoid retention cycle in AV completion closure
            Log.Tap.share(view: .SearchResult, parameters: itemParameters)
        }
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
}
