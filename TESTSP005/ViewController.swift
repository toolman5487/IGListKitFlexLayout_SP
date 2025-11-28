//
//  ViewController.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import UIKit
import IGListKit
import Combine
import SnapKit

class ViewController: UIViewController {
    private lazy var adapter: ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private let viewModel = PhotosViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchAllPhotos()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        adapter.collectionView = collectionView
        adapter.dataSource = self
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bindViewModel() {
        viewModel.$sectionModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.adapter.performUpdates(animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { error in
                print("Error fetching photos: \(error)")
            }
            .store(in: &cancellables)
    }
}

extension ViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        if let sectionModel = viewModel.sectionModel {
            return [sectionModel]
        }
        return []
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return PhotoSectionController()
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        return nil
    }
}

