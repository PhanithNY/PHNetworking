//
//  ParameterEncoder.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public protocol ParameterEncoder {
  func encode(urlRequest: inout URLRequest, with parameters: Parameter) throws
}

public enum ParameterEncoding {
  case urlEncoding
  case jsonEncoding
  case urlAndJsonEncoding
  
  public func encode(urlRequest: inout URLRequest,
                     bodyParameters: Parameter?,
                     urlParameters: Parameter?) throws {
    do {
      switch self {
      case .urlEncoding:
        guard let urlParameters = urlParameters else { return }
        try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
        
      case .jsonEncoding:
        guard let bodyParameters = bodyParameters else { return }
        try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
        
      case .urlAndJsonEncoding:
        guard let bodyParameters = bodyParameters,
              let urlParameters = urlParameters else { return }
        try URLParameterEncoder().encode(urlRequest: &urlRequest, with: urlParameters)
        try JSONParameterEncoder().encode(urlRequest: &urlRequest, with: bodyParameters)
        
      }
    } catch {
      throw error
    }
  }
}

