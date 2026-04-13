import Foundation

enum NetworkSecurityPolicy {
    static let pinnedDomains: Set<String> = [
        "api.plannerapp.io",
    ]

    static func makeSecureSession(delegate: URLSessionDelegate? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        if #available(iOS 15.0, macOS 12.0, *) {
            configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        }
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
}
