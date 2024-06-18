//
//  MultipleFileUploadServiceProvider.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public class MultipleFileUploadServiceProvider<T: Decodable>: NSObject, URLSessionTaskDelegate {
  
  // MARK: - Properties
  
  public typealias UploadResult = ((T?, Error?) -> Swift.Void)?
  public var onUploadProgress: ((Int64, Int64, Int64) -> Swift.Void)?
  private let target: MultipartType
  private let boundary: String
  
  // MARK: - Init
  
  public init(target: MultipartType) {
    self.target = target
    self.boundary = target.boundary
  }
  
  // MARK: - Actions
  
  public func upload(then result: UploadResult) {
    let urlString: String = "\(target.baseURL.absoluteString)\(target.path)"
    guard let url = URL(string: urlString) else {
      result?(nil, BadURLError())
      return
    }
    
    let request = buildRequest(from: url)
    let operationQueue = OperationQueue()
    let session = URLSession(configuration: .default, delegate: self, delegateQueue: operationQueue)
    session.dataTask(with: request) { (data, response, error) in
      if let response = response,
         let data = data {
        NetworkLogger.log(response: response, data: data)
      }
      
      if let error = error {
        result?(nil, error)
        return
      }
      
      if let data = data {
        do {
          let object = try JSONDecoder().decode(T.self, from: data)
          result?(object, nil)
        } catch {
          result?(nil, error)
        }
      }
    }.resume()
    
    
  }
  
  public func performUpload(queue: DispatchQueue = .main,
                            onSuccess: @escaping (Data) -> Swift.Void,
                            onError: @escaping (Error) -> Swift.Void) {
    let urlString: String = "\(target.baseURL.absoluteString)\(target.path)"
    guard let url = URL(string: urlString) else {
      onError(BadURLError())
      return
    }
    
    let request = buildRequest(from: url)
    let operationQueue = OperationQueue()
    let session = URLSession(configuration: .default,
                             delegate: self,
                             delegateQueue: operationQueue)
    session.dataTask(with: request) { (data, response, error) in
      
      if let response = response,
         let data = data {
        NetworkLogger.log(response: response, data: data)
      }
      
      queue.async {
        if let error = error {
          onError(error)
          return
        }
        
        guard let data, !data.isEmpty else {
          onError(EmptyDataError())
          return
        }
        
        onSuccess(data)
      }
      
    }.resume()
  }
  
  public func cancelTasks() {}
  
  private func buildRequest(from url: URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    if let headers = target.headers {
      for header in headers {
        request.setValue(header.value, forHTTPHeaderField: header.key)
      }
    }
    
    let dataBody = buildBodyData(using: target.params, medias: target.medias)
    request.httpBody = dataBody
    
    return request
  }
  
  private func buildBodyData(using params: [[String: Any]], medias: [Media]) -> Data {
    let lineBreak = "\r\n"
    var body = Data()
    
    for (index, param) in params.enumerated() {
      for (key, value) in param {
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(key)[\(index)]\"\(lineBreak + lineBreak)")
        body.append("\(value)" + "\(lineBreak)")
      }
    }
    
    let dictionary = Dictionary(grouping: medias, by: { $0.key })
    dictionary.forEach {
      for (index, media) in $0.value.enumerated() {
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(media.key)[\(index)]\"; filename=\"\(media.filename)\"\(lineBreak)")
        body.append("Content-Type: \(media.mimeType + lineBreak + lineBreak)")
        body.append(media.data)
        body.append(lineBreak)
      }
    }
    
    body.append("--\(boundary)--\(lineBreak)")
    
    return body
  }
  
  public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    DispatchQueue.main.async { [weak self] in
      self?.onUploadProgress?(bytesSent, totalBytesSent, totalBytesExpectedToSend)
    }
  }
}

extension Data {
  mutating func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      append(data)
    }
  }
}

public struct BadURLError: Error { }
public struct EmptyDataError: Error { }

struct _MainThread {
  static func run(_ block: @escaping (() -> Void)) {
    if Thread.isMainThread {
      block()
    } else {
      DispatchQueue.main.async {
        block()
      }
    }
  }
}
