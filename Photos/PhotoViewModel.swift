//
//  PhotoViewModel.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import Foundation
import Combine
import IGListKit

class PhotosSectionModel: ListDiffable {
    let photos: [Photo]
    
    init(photos: [Photo]) {
        self.photos = photos
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return "photos" as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? PhotosSectionModel else { return false }
        return photos.count == object.photos.count
    }
}

class PhotosViewModel: ObservableObject {
    
    @Published var sectionModel: PhotosSectionModel?
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private let photoService: PhotoServiceProtocol
    
    init(photoService: PhotoServiceProtocol = PhotoService()) {
        self.photoService = photoService
    }
    
    func fetchAllPhotos() {
        isLoading = true
        error = nil
        
        photoService.fetchPhotos()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] photos in
                    print("Loaded \(photos.count) photos")
                    self?.sectionModel = PhotosSectionModel(photos: photos)
                    self?.startRandomUpdates()
                }
            )
            .store(in: &cancellables)
    }

    private func startRandomUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self,
                  let current = self.sectionModel?.photos,
                  current.count > 1 else { return }
            
            var updated = current
            let fromIndex = Int.random(in: 0..<updated.count)
            let toIndex = Int.random(in: 0..<updated.count)
            let item = updated.remove(at: fromIndex)
            updated.insert(item, at: toIndex)
            
            self.sectionModel = PhotosSectionModel(photos: updated)
        }
    }
}
