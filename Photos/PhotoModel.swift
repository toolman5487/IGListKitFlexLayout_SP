//
//  PhotoModel.swift
//  TESTSP005
//
//  Created by Willy Hsu on 2025/11/28.
//

import Foundation

struct Photo: Codable, Hashable, Sendable {
    let albumId: Int
    let id: Int
    let title: String
    let url: String
    let thumbnailUrl: String
}