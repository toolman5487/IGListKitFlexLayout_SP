//
//  PhotoSectionController.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import UIKit
import IGListKit

class PhotoSectionController: ListSectionController {
    private var sectionModel: PhotosSectionModel?
    
    override init() {
        super.init()
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        minimumLineSpacing = 2
        minimumInteritemSpacing = 2
    }
    
    override func numberOfItems() -> Int {
        return sectionModel?.photos.count ?? 0
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        guard let context = collectionContext else { return .zero }
        let width = context.containerSize.width
        let spacing: CGFloat = 2
        let totalSpacing = spacing * 2
        let itemWidth = floor((width - totalSpacing) / 3)
        return CGSize(width: itemWidth, height: itemWidth)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(
            of: PhotoCell.self,
            for: self,
            at: index
        ) as? PhotoCell,
        let photo = sectionModel?.photos[index] else {
            return UICollectionViewCell()
        }
        
        cell.configure(with: photo)
        return cell
    }
    
    override func didUpdate(to object: Any) {
        sectionModel = object as? PhotosSectionModel
    }
}

