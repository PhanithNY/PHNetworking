//
//  SingleFileUploadServiceProvider.swift
//
//
//  Created by Suykorng on 16/4/24.
//

import Foundation

public struct SingleFileUploadServiceProvider<T: Decodable> {
  
  // MARK: - Properties
  
  public typealias UploadResult = ((T?, Error?) -> Swift.Void)?
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
    if NetworkLogger.shared.logStatus == .enable {
      NetworkLogger.log(request: request)
    }
    
    let session = URLSession.shared
    session.dataTask(with: request) { (data, response, error) in
      if NetworkLogger.shared.logStatus == .enable,
         let response = response,
         let data = data {
        NetworkLogger.log(response: response, data: data)
      }
      
      _MainThread.run {
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
    
    if let media = target.medias.first {
      let param = target.params.first ?? [:]
      let dataBody = buildBodyData(using: param, media: media)
      request.httpBody = dataBody
    }
    
    return request
  }
  
  private func buildBodyData(using param: [String: Any], media: Media) -> Data {
    let lineBreak = "\r\n"
    var body = Data()
    
    for (key, value) in param {
      body.append("--\(boundary + lineBreak)")
      body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
      body.append("\(value)" + "\(lineBreak)")
    }
    
    body.append("--\(boundary + lineBreak)")
    body.append("Content-Disposition: form-data; name=\"\(media.key)\"; filename=\"\(media.filename)\"\(lineBreak)")
    body.append("Content-Type: \(media.mimeType + lineBreak + lineBreak)")
    body.append(media.data)
    body.append(lineBreak)
    
    body.append("--\(boundary)--\(lineBreak)")
    
    return body
  }
}
