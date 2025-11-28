//
//  NativeCollectionViewController.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import UIKit
import Combine
import SnapKit

class NativeCollectionViewController: UIViewController {
    private var collectionView: UICollectionView!
    private let viewModel = NativePhotoViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchPhotos()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(NativePhotoCell.self, forCellWithReuseIdentifier: "NativePhotoCell")
        
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bindViewModel() {
        viewModel.$photos
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("Native: Error fetching photos: \(error)")
            }
            .store(in: &cancellables)
    }
}

extension NativeCollectionViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NativePhotoCell", for: indexPath) as! NativePhotoCell
        let photo = viewModel.photos[indexPath.item]
        cell.configure(with: photo)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let spacing: CGFloat = 2
        let totalSpacing = spacing * 2
        let itemWidth = floor((width - totalSpacing) / 3)
        return CGSize(width: itemWidth, height: itemWidth)
    }
}
