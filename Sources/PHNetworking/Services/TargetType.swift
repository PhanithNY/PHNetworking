//
//  TargetType.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public protocol TargetType {
  var baseURL: URL { get }
  var path: String { get }
  var httpMethod: HTTPMethod { get }
  var task: HTTPTask { get }
  var headers: HTTPHeaders? { get }
  var defaultHeaders: HTTPHeaders? { get }
}
