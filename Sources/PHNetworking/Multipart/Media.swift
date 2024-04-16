//
//  Media.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public struct Media {
  let key: String
  let filename: String
  let data: Data
  let mimeType: String
  
  public init(data: Data, key: String, filename: String, fileExtension: String, mimeType: MimeType) {
    self.data = data
    self.key = key
    self.filename = "\(filename).\(fileExtension)"
    self.mimeType = mimeType.rawValue
  }
}
