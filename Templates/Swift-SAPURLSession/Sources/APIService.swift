{% include "Includes/Header.stencil" %}

{{ options.apiAccessLevel }} struct APIService<ResponseType: APIResponseValue> {

    {{ options.apiAccessLevel }} let id: String
    {{ options.apiAccessLevel }} let tag: String
    {{ options.apiAccessLevel }} let method: String
    {{ options.apiAccessLevel }} let path: String
    {{ options.apiAccessLevel }} let hasBody: Bool
    {{ options.apiAccessLevel }} let isUpload: Bool

    {{ options.apiAccessLevel }} init(id: String, tag: String = "", method:String, path:String, hasBody: Bool, isUpload: Bool = false) {
        self.id = id
        self.tag = tag
        self.method = method
        self.path = path
        self.hasBody = hasBody
        self.isUpload = isUpload
    }
}

extension APIService: CustomStringConvertible {

    {{ options.apiAccessLevel }} var name: String {
        return "\(tag.isEmpty ? "" : "\(tag).")\(id)"
    }

    {{ options.apiAccessLevel }} var description: String {
        return "\(name): \(method) \(path)"
    }
}

{{ options.apiAccessLevel }} struct SecurityRequirement {
    {{ options.apiAccessLevel }} let type: String
    {{ options.apiAccessLevel }} let scopes: [String]

    {{ options.apiAccessLevel }} init(type: String, scopes: [String]) {
        self.type = type
        self.scopes = scopes
    }
}

