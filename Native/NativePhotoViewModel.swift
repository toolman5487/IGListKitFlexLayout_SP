//
//  NativePhotoViewModel.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import Foundation
import Combine

class NativePhotoViewModel: ObservableObject {
    
    @Published var photos: [Photo] = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private let photoService: PhotoServiceProtocol
    
    init(photoService: PhotoServiceProtocol = PhotoService()) {
        self.photoService = photoService
    }
    
    func fetchPhotos() {
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
                    print("Native: Loaded \(photos.count) photos")
                    self?.photos = photos
                    self?.startRandomUpdates()
                }
            )
            .store(in: &cancellables)
    }

    private func startRandomUpdates() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self,
                  self.photos.count > 1 else { return }
            
            var updated = self.photos
            let fromIndex = Int.random(in: 0..<updated.count)
            let toIndex = Int.random(in: 0..<updated.count)
            let item = updated.remove(at: fromIndex)
            updated.insert(item, at: toIndex)
            
            self.photos = updated
        }
    }
}

