{% include "Includes/Header.stencil" %}

import Combine
import Foundation
import SAPFoundation

/// Manages and sends APIRequests
{{ options.apiAccessLevel }} class APIClient {

    /// The base url prepended before every request path
    {{ options.apiAccessLevel }} var baseURL: String

    /// The SAPFoundation's SAPURLSession used for each request
    {{ options.apiAccessLevel }} var sapURLSession: SAPURLSession

    {{ options.apiAccessLevel }} var jsonDecoder = JSONDecoder()
    {{ options.apiAccessLevel }} var jsonEncoder = JSONEncoder()

    {{ options.apiAccessLevel }} var decodingQueue = DispatchQueue(label: "apiClient", qos: .utility, attributes: .concurrent)

    {{ options.apiAccessLevel }} init(baseURL: String, sapURLSession: SAPURLSession) {
        self.baseURL = baseURL
        self.sapURLSession = sapURLSession
        jsonDecoder.dateDecodingStrategy = .custom(dateDecoder)
        jsonEncoder.dateEncodingStrategy = .formatted(ARService.dateEncodingFormatter)
    }

    // MARK: Callback-based APIs

    /// Makes a network request
    ///
    /// - Parameters:
    ///   - request: The API request to make
    ///   - completionQueue: The queue that complete will be called on
    ///   - complete: A closure that gets passed the APIResponse
    /// - Returns: A cancellable SAPURLSessionTask
    @discardableResult
    {{ options.apiAccessLevel }} func makeRequest<T>(_ request: APIRequest<T>, completionQueue: DispatchQueue = DispatchQueue.main, complete: @escaping (APIResponse<T>) -> Void) -> SAPURLSessionTask? {

        // create the url request from the request
        var urlRequest: URLRequest
        do {
            guard let safeURL = URL(string: baseURL) else {
                throw InternalError.malformedURL
            }

            urlRequest = try request.createURLRequest(baseURL: safeURL, encoder: jsonEncoder)
        } catch {
            let error = APIClientError.requestEncodingError(error)
            let response = APIResponse<T>(request: request, result: .failure(error))
            complete(response)
            return nil
        }

        return makeNetworkRequest(request: request, urlRequest: urlRequest, completionQueue: completionQueue, complete: complete)
    }

    internal func makeNetworkRequest<T>(request: APIRequest<T>, urlRequest: URLRequest, completionQueue: DispatchQueue, complete: @escaping (APIResponse<T>) -> Void) -> SAPURLSessionTask {
        var urlRequest = urlRequest
        if request.service.isUpload {
            let builder = MultipartFormDataBuilder()
            for (name, value) in request.formParameters {
                if let file = value as? UploadFile {
                    switch file.type {
                    case let .data(data):
                        if let fileName = file.fileName, let mimeType = file.mimeType {
                            builder.addDataField(named: fileName, data: data, mimeType: mimeType)
                        }
                    case .url(_):
						assert(false, "NOT SUPPORTED YET")
                    }
                } else if let string = value as? String {
                    builder.addTextField(named: name, value: string)
                }
            }
            urlRequest = builder.applyFormFields(to: urlRequest)
        }

        let task = sapURLSession.dataTask(with: urlRequest) { data, urlResponse, error in
            self.handleResponse(request: request, urlRequest: urlRequest, data: data, urlResponse: urlResponse, error: error, completionQueue: completionQueue, complete: complete)
        }

        task.resume()

        return task
    }

    internal func handleResponse<T>(request: APIRequest<T>, urlRequest: URLRequest, data: Data?, urlResponse: URLResponse?, error: Error?, completionQueue: DispatchQueue, complete: @escaping (APIResponse<T>) -> Void) {
        var result: APIResult<T>

        if let error = error {

            let apiError = APIClientError.networkError(error)
            result = .failure(apiError)
            let response = APIResponse<T>(request: request, result: result, urlRequest: urlRequest, urlResponse: urlResponse as? HTTPURLResponse, data: data)

            completionQueue.async {
                complete(response)
            }
        }

        do {
            guard let httpResponse = urlResponse as? HTTPURLResponse, let value = data else {
                throw InternalError.emptyResponse
            }
            let decoded = try T(statusCode: httpResponse.statusCode, data: value, decoder: jsonDecoder)
            result = .success(decoded)
        } catch let error {
            let apiError: APIClientError
            if let error = error as? DecodingError {
                apiError = APIClientError.decodingError(error)
            } else if let error = error as? APIClientError {
                apiError = error
            } else {
                apiError = APIClientError.unknownError(error)
            }
            result = .failure(apiError)
        }

        let response = APIResponse<T>(request: request, result: result, urlRequest: urlRequest, urlResponse: urlResponse as? HTTPURLResponse, data: data)

        completionQueue.async {
            complete(response)
        }
    }

    // MARK: Combine/Publisher-based APIs

    /// Makes a network request (Combine-based )
    ///  Combine
    /// - Parameter request: The API request to make
    /// - Returns: Publisher with API Response (cannot fail)
    {{ options.apiAccessLevel }} func makeRequest<T>(_ request: APIRequest<T>) -> AnyPublisher<APIResponse<T>, Never> {

        // create the url request from the request
        var urlRequest: URLRequest
        do {
            guard let safeURL = URL(string: baseURL) else {
                throw InternalError.malformedURL
            }

            urlRequest = try request.createURLRequest(baseURL: safeURL, encoder: jsonEncoder)
        } catch {
            let error = APIClientError.requestEncodingError(error)
            let response = APIResponse<T>(request: request, result: .failure(error))
            return Just(response).eraseToAnyPublisher()
        }

        return makeNetworkRequest(request: request, urlRequest: urlRequest)
    }

    internal func makeNetworkRequest<T>(request: APIRequest<T>, urlRequest: URLRequest) -> AnyPublisher<APIResponse<T>, Never> {
        var urlRequest = urlRequest
        if request.service.isUpload {
            let builder = MultipartFormDataBuilder()
            for (name, value) in request.formParameters {
                if let file = value as? UploadFile {
                    switch file.type {
                    case let .data(data):
                        if let fileName = file.fileName, let mimeType = file.mimeType {
                            builder.addDataField(named: fileName, data: data, mimeType: mimeType)
                        }
                    case .url(_):
                        assert(false, "NOT SUPPORTED YET")
                    }
                } else if let string = value as? String {
                    builder.addTextField(named: name, value: string)
                }
            }
            urlRequest = builder.applyFormFields(to: urlRequest)
        }

        return sapURLSession.dataTaskPublisher(for: urlRequest)
            .flatMap({ yoo in
                self.handleResponse(request: request, urlRequest: urlRequest, data: yoo.data, urlResponse: yoo.response, error: nil)
            })
            .catch { err in
                return Just(APIResponse<T>(request: request, result: .failure(APIClientError.unknownError(err)), urlRequest: urlRequest, urlResponse: nil, data: nil))
            }
            .eraseToAnyPublisher()
    }

    internal func handleResponse<T>(request: APIRequest<T>, urlRequest: URLRequest, data: Data?, urlResponse: URLResponse?, error: Error?) -> AnyPublisher<APIResponse<T>, Never> {
        var result: APIResult<T>

        if let error = error {

            let apiError = APIClientError.networkError(error)
            result = .failure(apiError)
            let response = APIResponse<T>(request: request, result: result, urlRequest: urlRequest, urlResponse: urlResponse as? HTTPURLResponse, data: data)

            return Just(response).eraseToAnyPublisher()
        }

        do {
            guard let httpResponse = urlResponse as? HTTPURLResponse, let value = data else {
                throw InternalError.emptyResponse
            }
            let decoded = try T(statusCode: httpResponse.statusCode, data: value, decoder: jsonDecoder)
            result = .success(decoded)
        } catch let error {
            let apiError: APIClientError
            if let error = error as? DecodingError {
                apiError = APIClientError.decodingError(error)
            } else if let error = error as? APIClientError {
                apiError = error
            } else {
                apiError = APIClientError.unknownError(error)
            }
            result = .failure(apiError)
        }

        let response = APIResponse<T>(request: request, result: result, urlRequest: urlRequest, urlResponse: urlResponse as? HTTPURLResponse, data: data)

        return Just(response).eraseToAnyPublisher()
    }    
}


{{ options.apiAccessLevel }} extension APIClient {
    enum InternalError: Error {
        case malformedURL
        case emptyResponse
    }
}

// Create URLRequest
extension APIRequest {

    {{ options.apiAccessLevel }} func createURLRequest(baseURL: URL, encoder: RequestEncoder = JSONEncoder()) throws -> URLRequest {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = service.method
        urlRequest.allHTTPHeaderFields = headers

        // filter out parameters with empty string value
        var queryParams: [String: Any] = [:]
        for (key, value) in queryParameters {
            if !String(describing: value).isEmpty {
                queryParams[key] = value
            }
        }

        if !queryParams.isEmpty {
            urlRequest = try URLEncoding.queryString.encode(urlRequest, with: queryParams)
        }

        var formParams: [String: Any] = [:]
        for (key, value) in formParameters {
            if !String(describing: value).isEmpty {
                formParams[key] = value
            }
        }

        if !formParams.isEmpty {
            urlRequest = try URLEncoding.httpBody.encode(urlRequest, with: formParams)
        }

        if let encodeBody = encodeBody {
            urlRequest.httpBody = try encodeBody(encoder)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }
}

{{ options.apiAccessLevel }} extension URLRequest {
    var method: HTTPMethod? {
        guard let httpMethod = self.httpMethod else { return nil }
        return HTTPMethod(rawValue: httpMethod)
    }
}
