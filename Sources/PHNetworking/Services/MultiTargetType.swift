//
//  MultiTargetType.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public enum MultiTargetType: TargetType {
  
  case target(TargetType)
  
  public init(_ target: TargetType) {
    self = MultiTargetType.target(target)
  }
  
  public var path: String {
    return target.path
  }
  
  public var baseURL: URL {
    return target.baseURL
  }
  
  public var httpMethod: HTTPMethod {
    return target.httpMethod
  }
  
  public var task: HTTPTask {
    return target.task
  }
  
  public var headers: [String: String]? {
    return target.headers
  }
  
  public var target: TargetType {
    switch self {
    case .target(let target): return target
    }
  }
  
  public var defaultHeaders: HTTPHeaders? {
    return target.defaultHeaders
  }
}
