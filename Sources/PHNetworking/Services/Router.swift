//
//  File.swift
//  
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public final class Router<Endpoint: TargetType>: APIClientRouter {
  
  private var task: URLSessionTask?
  
  public init() {}
  
  public final func request(_ route: Endpoint,
                            callbackQueue queue: DispatchQueue = .main,
                            completion: @escaping APIClientRouterCompletion) {
    let session = URLSession.shared
    do {
      let request = try self.buildRequest(from: route)
      if NetworkLogger.shared.logStatus == .enable {
        NetworkLogger.log(request: request)
      }
      task = session.dataTask(with: request, completionHandler: { data, response, error in
        queue.async {
          completion(data, response, error)
        }
        if NetworkLogger.shared.logStatus == .enable,
           let response = response,
           let data = data {
          NetworkLogger.log(response: response, data: data)
        }
      })
    } catch {
      queue.async {
        completion(nil, nil, error)
      }
    }
    task?.resume()
  }
  
  public final func cancel() {
    if task?.state == .some(.running) {
      task?.suspend()
    }
    task?.cancel()
#if DEBUG
    print("Cancel task \(task?.taskIdentifier ?? -1)")
#endif
  }
  
  fileprivate func buildRequest(from route: Endpoint) throws -> URLRequest {
    
    var request = URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                             cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                             timeoutInterval: 120)
    
    request.httpMethod = route.httpMethod.rawValue
    do {
      switch route.task {
      case .request:
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        self.addAdditionalHeaders(route.headers, request: &request)
        
      case .requestParameters(let bodyParameters, let bodyEncoding,let urlParameters):
        self.addAdditionalHeaders(route.headers, request: &request)
        try self.configureParameters(bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, urlParameters: urlParameters, request: &request)
        
      case .requestParametersAndHeaders(let bodyParameters, let bodyEncoding, let urlParameters, let additionalHeaders):
        self.addAdditionalHeaders(additionalHeaders, request: &request)
        try self.configureParameters(bodyParameters: bodyParameters, bodyEncoding: bodyEncoding, urlParameters: urlParameters, request: &request)
      }
      return request
    } catch {
      throw error
    }
  }
  
  fileprivate func configureParameters(bodyParameters: Parameter?, bodyEncoding: ParameterEncoding, urlParameters: Parameter?, request: inout URLRequest) throws {
    do {
      try bodyEncoding.encode(urlRequest: &request, bodyParameters: bodyParameters, urlParameters: urlParameters)
    } catch {
      throw error
    }
  }
  
  fileprivate func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
    guard let headers = additionalHeaders else { return }
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
  }
}

fileprivate protocol APIClientRouter: AnyObject {
  associatedtype Endpoint: TargetType
  func request(_ route: Endpoint, callbackQueue queue: DispatchQueue, completion: @escaping APIClientRouterCompletion)
  func cancel()
}
