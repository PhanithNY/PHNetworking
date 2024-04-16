//
//  HTTPTask.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public enum HTTPTask {
  case request
  case requestParameters(bodyParameters: Parameter?, bodyEncoding: ParameterEncoding, urlParameters: Parameter?)
  case requestParametersAndHeaders(bodyParameters: Parameter?, bodyEncoding: ParameterEncoding, urlParameters: Parameter?, additionHeaders: HTTPHeaders?)
}
