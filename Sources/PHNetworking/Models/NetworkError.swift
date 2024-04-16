//
//  NetworkError.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public enum NetworkError : String, Error {
  case parametersNil = "Parameters were nil."
  case encodingFailed = "Parameter encoding failed."
  case missingURL = "URL is nil."
  case noConnection = "No Internet Connection."
}
