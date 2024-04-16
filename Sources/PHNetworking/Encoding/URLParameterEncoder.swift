//
//  URLParameterEncoder.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public struct URLParameterEncoder: ParameterEncoder {
  public func encode(urlRequest: inout URLRequest, with parameters: Parameter) throws {
    if [HTTPMethod.get.rawValue, HTTPMethod.delete.rawValue].contains(urlRequest.httpMethod.optionallyEmpty) {
      guard let url = urlRequest.url else {
        throw NetworkError.missingURL
      }
      
      if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
        let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
        urlComponents.percentEncodedQuery = percentEncodedQuery
        urlRequest.url = urlComponents.url
      }
    } else {
      if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
        urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
      }
      
      if !parameters.isEmpty {
        urlRequest.httpBody = Data(query(parameters).utf8)
      }
    }
  }
  
  private func escape(_ string: String) -> String {
    string.addingPercentEncoding(withAllowedCharacters: .wingURLQueryAllowed).optionallyEmpty
  }
  
  private func query(_ parameters: [String: Any]) -> String {
    var components: [(String, String)] = []
    
    for key in parameters.keys.sorted(by: <) {
      let value = parameters[key]!
      components += queryComponents(fromKey: key, value: value)
    }
    return components.map { "\($0)=\($1)" }.joined(separator: "&")
  }
  
  private func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
    return [(escape(key), escape("\(value)"))]
  }
}

fileprivate extension URLRequest {
  func percentEscapeString(_ string: String) -> String {
    var characterSet = CharacterSet.alphanumerics
    characterSet.insert(charactersIn: "-._* ")
    
    return string
      .addingPercentEncoding(withAllowedCharacters: characterSet).optionallyEmpty
      .replacingOccurrences(of: " ", with: "+")
      .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
  }
  
  mutating func encodeParameters(parameters: [String : Any]) {
    let parameterArray = parameters.map { "\($0.key)=\(self.percentEscapeString("\($0.value)"))" }
    httpBody = parameterArray.joined(separator: "&").data(using: .utf8)
  }
}

fileprivate extension CharacterSet {
  /// Creates a CharacterSet from RFC 3986 allowed characters.
  ///
  /// RFC 3986 states that the following characters are "reserved" characters.
  ///
  /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
  /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
  ///
  /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
  /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
  /// should be percent-escaped in the query string.
  static let wingURLQueryAllowed: CharacterSet = {
    let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
    let subDelimitersToEncode = "!$&'()*+,;="
    let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
    return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
  }()
}

