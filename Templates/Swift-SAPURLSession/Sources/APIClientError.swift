{% include "Includes/Header.stencil" %}

import Foundation

{{ options.apiAccessLevel }} enum APIClientError: Error {
    case unexpectedStatusCode(statusCode: Int, data: Data)
	case encodingError(Error)
    case decodingError(DecodingError)
    case requestEncodingError(Error)
    case validationError(Error)
    case networkError(Error)
    case unknownError(Error)

    {{ options.apiAccessLevel }} var name:String {
        switch self {
        case .unexpectedStatusCode: return "Unexpected status code"
        case .encodingError: return "Encoding error"
        case .decodingError: return "Decoding error"
        case .validationError: return "Request validation failed"
        case .requestEncodingError: return "Request encoding failed"
        case .networkError: return "Network error"
        case .unknownError: return "Unknown error"
        }
    }
}

extension APIClientError: CustomStringConvertible {

    {{ options.apiAccessLevel }} var description:String {
        switch self {
        case .unexpectedStatusCode(let statusCode, _): return "\(name): \(statusCode)"
        case .encodingError(let error): return "\(name): \(error.localizedDescription)\n\(error)"
        case .decodingError(let error): return "\(name): \(error.localizedDescription)\n\(error)"
        case .validationError(let error): return "\(name): \(error.localizedDescription)"
        case .requestEncodingError(let error): return "\(name): \(error)"
        case .networkError(let error): return "\(name): \(error.localizedDescription)"
        case .unknownError(let error): return "\(name): \(error.localizedDescription)"
        }
    }
}
