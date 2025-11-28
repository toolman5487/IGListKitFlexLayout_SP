//
//  PhotoService.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import Foundation
import Combine

protocol PhotoServiceProtocol {
    func fetchPhotos() -> AnyPublisher<[Photo], Error>
}

class PhotoService: PhotoServiceProtocol {
    func fetchPhotos() -> AnyPublisher<[Photo], Error> {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/photos") else {
            return Fail(error: NSError(domain: "Invalid URL", code: -1))
                .eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Photo].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}