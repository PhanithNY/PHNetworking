//
//  File.swift
//  
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public enum HTTPMethod: String, CaseIterable {
  case get     = "GET"
  case post    = "POST"
  case put     = "PUT"
  case patch   = "PATCH"
  case delete  = "DELETE"
}
