//
//  MultipartType.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public protocol MultipartType {
  var baseURL: URL { get }
  var path: String { get }
  var headers: HTTPHeaders? { get }
  var params: [[String: Any]] { get }
  var medias: [MultipartForm.Part] { get }
  var boundary: String { get }
}
