{% include "Includes/Header.stencil" %}

import Foundation

{{ options.apiAccessLevel }} class APIRequest<ResponseType: APIResponseValue> {

    {{ options.apiAccessLevel }} let service: APIService<ResponseType>
    {{ options.apiAccessLevel }} private(set) var queryParameters: [String: Any]
    {{ options.apiAccessLevel }} private(set) var formParameters: [String: Any]
    {{ options.apiAccessLevel }} let encodeBody: ((RequestEncoder) throws -> Data)?
    {{ options.apiAccessLevel }}(set) var headerParameters: [String: String]
    {{ options.apiAccessLevel }} var customHeaders: [String: String] = [:]

    {{ options.apiAccessLevel }} var headers: [String: String] {
        return headerParameters.merging(customHeaders) { param, custom in return custom }
    }

    {{ options.apiAccessLevel }} var path: String {
        return service.path
    }

    {{ options.apiAccessLevel }} init(service: APIService<ResponseType>,
                queryParameters: [String: Any] = [:],
                formParameters: [String: Any] = [:],
                headers: [String: String] = [:],
                encodeBody: ((RequestEncoder) throws -> Data)? = nil) {
        self.service = service
        self.queryParameters = queryParameters
        self.formParameters = formParameters
        self.headerParameters = headers
        self.encodeBody = encodeBody
    }
}

extension APIRequest: CustomStringConvertible {

    {{ options.apiAccessLevel }} var description: String {
        var string = "\(service.name): \(service.method) \(path)"
        if !queryParameters.isEmpty {
            string += "?" + queryParameters.map {"\($0)=\($1)"}.joined(separator: "&")
        }
        return string
    }
}

extension APIRequest: CustomDebugStringConvertible {

    {{ options.apiAccessLevel }} var debugDescription: String {
        var string = description
        if let encodeBody = encodeBody,
            let data = try? encodeBody(JSONEncoder()),
            let bodyString = String(data: data, encoding: .utf8) {
            string += "\nbody: \(bodyString)"
        }
        return string
    }
}

/// A file upload
{{ options.apiAccessLevel }} struct UploadFile: Equatable {

    {{ options.apiAccessLevel }} let type: FileType
    {{ options.apiAccessLevel }} let fileName: String?
    {{ options.apiAccessLevel }} let mimeType: String?

    {{ options.apiAccessLevel }} init(type: FileType) {
        self.type = type
        self.fileName = nil
        self.mimeType = nil
    }

    {{ options.apiAccessLevel }} init(type: FileType, fileName: String, mimeType: String) {
        self.type = type
        self.fileName = fileName
        self.mimeType = mimeType
    }

    {{ options.apiAccessLevel }} enum FileType: Equatable {
        case data(Data)
        case url(URL)
    }

    func encode() -> Any {
        return self
    }
}
