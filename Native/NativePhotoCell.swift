//
//  NativePhotoCell.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import UIKit
import SDWebImage
import SnapKit

class NativePhotoCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .white
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(20)
        }
    }
    
    func configure(with photo: Photo) {
        let placeholder = generatePlaceholderImage(id: photo.id)
        imageView.image = placeholder
        titleLabel.text = photo.title
        
        let imageUrl = "https://picsum.photos/150/150?random=\(photo.id)"
        guard let url = URL(string: imageUrl) else {
            imageView.image = placeholder
            return
        }
        
        imageView.sd_setImage(
            with: url,
            placeholderImage: placeholder,
            options: [.retryFailed, .refreshCached, .highPriority],
            progress: nil
        ) { [weak self] image, error, cacheType, imageURL in
            if let error = error {
                DispatchQueue.main.async {
                    self?.imageView.image = placeholder
                }
            }
        }
    }
    
    private func generatePlaceholderImage(id: Int) -> UIImage? {
        let size = CGSize(width: 150, height: 150)
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple, .systemRed, .systemYellow]
        let color = colors[id % colors.count]
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        titleLabel.text = nil
    }
}

