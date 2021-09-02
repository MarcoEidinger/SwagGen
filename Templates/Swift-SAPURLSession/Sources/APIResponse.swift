{% include "Includes/Header.stencil" %}

import Foundation

{{ options.apiAccessLevel }} protocol APIResponseValue: CustomDebugStringConvertible, CustomStringConvertible {
    associatedtype SuccessType{% if options.codableResponses %} : Codable{% endif %}
    var statusCode: Int { get }
    var successful: Bool { get }
    var response: Any { get }
    init(statusCode: Int, data: Data, decoder: ResponseDecoder) throws
    var success: SuccessType? { get }
}

{{ options.apiAccessLevel }} enum APIResponseResult<SuccessType, FailureType>: CustomStringConvertible, CustomDebugStringConvertible {
    case success(SuccessType)
    case failure(FailureType)

    {{ options.apiAccessLevel }} var value: Any {
        switch self {
        case .success(let value): return value
        case .failure(let value): return value
        }
    }

    {{ options.apiAccessLevel }} var successful: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }

    {{ options.apiAccessLevel }} var description: String {
        return "\(successful ? "success" : "failure")"
    }

    {{ options.apiAccessLevel }} var debugDescription: String {
        return "\(description):\n\(value)"
    }
}

{{ options.apiAccessLevel }} struct APIResponse<T: APIResponseValue> {

    /// The APIRequest used for this response
    {{ options.apiAccessLevel }} let request: APIRequest<T>

    /// The result of the response .
    {{ options.apiAccessLevel }} let result: APIResult<T>

    /// The URL request sent to the server.
    {{ options.apiAccessLevel }} let urlRequest: URLRequest?

    /// The server's response to the URL request.
    {{ options.apiAccessLevel }} let urlResponse: HTTPURLResponse?

    /// The data returned by the server.
    {{ options.apiAccessLevel }} let data: Data?

    /// The timeline of the complete lifecycle of the request.
    {{ options.apiAccessLevel }} let metrics: URLSessionTaskMetrics?

    init(request: APIRequest<T>, result: APIResult<T>, urlRequest: URLRequest? = nil, urlResponse: HTTPURLResponse? = nil, data: Data? = nil, metrics: URLSessionTaskMetrics? = nil) {
        self.request = request
        self.result = result
        self.urlRequest = urlRequest
        self.urlResponse = urlResponse
        self.data = data
        self.metrics = metrics
    }
}

extension APIResponse: CustomStringConvertible, CustomDebugStringConvertible {

    {{ options.apiAccessLevel }} var description:String {
        var string = "\(request)"

        switch result {
        case .success(let value):
            string += " returned \(value.statusCode)"
            let responseString = "\(type(of: value.response))"
            if responseString != "()" {
                string += ": \(responseString)"
            }
        case .failure(let error): string += " failed: \(error)"
        }
        return string
    }

    {{ options.apiAccessLevel }} var debugDescription: String {
        var string = description
        if let response = try? result.get().response {
          if let debugStringConvertible = response as? CustomDebugStringConvertible {
              string += "\n\(debugStringConvertible.debugDescription)"
          }
        }
        return string
    }
}
