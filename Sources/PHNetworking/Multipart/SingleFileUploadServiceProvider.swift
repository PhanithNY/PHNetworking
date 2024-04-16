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
    
    let session = URLSession.shared
    session.dataTask(with: request) { (data, response, error) in
      if let response = response,
         let data = data {
        if NetworkLogger.shared.logStatus == .enable {
          NetworkLogger.log(response: response, data: data)
        }
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
  
  public func cancelTasks() {}
  
  private func buildRequest(from url: URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.timeoutInterval = 120
    request.httpMethod = "POST"
    
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
    if let headers = target.headers {
      for header in headers {
        request.setValue(header.value, forHTTPHeaderField: header.key)
      }
    }
    
    if let media = target.medias.first {
      let param = target.params.first ?? [:]
      let form = buildBodyData(using: param, media: media)
      request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
      request.httpBody = form.bodyData
    }
    
    return request
  }
  
  private func buildBodyData(using param: [String: Any], media: MultipartForm.Part) -> MultipartForm {
    let paramParts: [MultipartForm.Part] = param.map {
      MultipartForm.Part(name: $0.key, value: "\($0.value)")
    }
    var parts: [MultipartForm.Part] = paramParts
    parts.append(media)
    
    let form = MultipartForm(parts: parts)
    return form
  }
}
