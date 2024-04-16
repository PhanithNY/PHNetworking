//
//  NetworkLogger.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation
import OSLog

@available(iOS 14.0, *)
extension Logger {
  private static var subsystem = "PHNetworking"
  
  static let outgoing = Logger(subsystem: subsystem, category: "outgoing")
  
  static let incoming = Logger(subsystem: subsystem, category: "incoming")
}

public final class NetworkLogger {
  
  public enum LogStatus {
    case enable
    case disable
  }
  
  static let shared = NetworkLogger()
  private(set) var logStatus: LogStatus = .disable
  private init() {}
  
  public static func log(_ status: LogStatus) {
    shared.logStatus = status
  }
  
  public static func log(request: URLRequest) {
    let log = request.toJSONLog()
    let json = """
        ================================  OUTGOING  =================================
        \(log)
        ================================  FINISHED  =================================
        """
    if #available(iOS 14.0, *) {
      Logger.outgoing.debug("\(json, privacy: .sensitive)")
    } else {
      print(json)
    }
  }
  
  public static func log(response: URLResponse, data: Data) {
    let log = response.toJSONLog(with: data)
    let json = """
        ================================  INCOMING  =================================
        \(log)
        ================================  FINISHED  =================================
        """
    if #available(iOS 14.0, *) {
      Logger.incoming.debug("\(json, privacy: .sensitive)")
    } else {
      print(json)
    }
  }
}

public extension URLRequest {
  func toJSONLog() -> String {
    let request = self
    let urlAsString = request.url?.absoluteString ?? ""
    let urlComponents = NSURLComponents(string: urlAsString)
    
    let method = request.httpMethod != nil ? "\(request.httpMethod.optionallyEmpty)" : ""
    let path = "\(urlComponents.map { $0.path.optionallyEmpty }.optionallyEmpty)"
    let query = "\(urlComponents.map { $0.query.optionallyEmpty }.optionallyEmpty)"
    let host = "\(urlComponents.map { $0.host.optionallyEmpty }.optionallyEmpty)"
    
    var logOutput = """
        \(urlAsString) \n
        HOST: \(host)
        Method: \(method)
        Path: \(path)?\(query) \n
        """
    
    for (key,value) in request.allHTTPHeaderFields ?? [:] {
      logOutput += "\(key): \(value) \n"
    }
    
    if let body = request.httpBody {
      if let requestBody = NSString(data: body, encoding: String.Encoding.utf8.rawValue), requestBody != "" {
        logOutput += "Request body:\n\(requestBody)"
      } else {
        if let json = try? JSON(data: body), json != .null {
          logOutput += "Request body:\n\(json)"
        }
      }
    }
    return logOutput
  }
}

public extension URLResponse {
  func toJSONLog(with data: Data) -> String {
    let response = self
    var content: String = ""
    if let response = response as? HTTPURLResponse {
      content += "\nStatus Code: \(response.statusCode)\n"
      content += "Response From:\n\(response.url.map { $0.absoluteString }.optionallyEmpty)"
    }
    
    if let jsonResponse = data.json,
       jsonResponse != .null {
      return
        """
        \(content)
        \(jsonResponse)
        """
    } else {
      let jsonData: String = data.prettyPrintedJSONString.optionallyEmpty
      return
        """
        \(content)
        \(jsonData)
        """
    }
  }
}

public extension Data {
  var json: JSON? {
    try? JSON(data: self, options: [])
  }
  
  var prettyPrintedJSONString: String? {
    guard
      let object = try? JSONSerialization.jsonObject(with: self, options: []),
      let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
      let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
      return nil
    }
    let result = prettyPrintedString.replacingOccurrences(of: "\\/", with: "/")
    return result
  }
}
