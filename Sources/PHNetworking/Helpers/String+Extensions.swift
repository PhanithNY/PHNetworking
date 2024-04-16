//
//  String+Extensions.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

extension Optional where Wrapped == String {
  var optionallyEmpty: String {
    switch self {
    case .some(let value):
      return value
    case .none:
      return ""
    }
  }
}
