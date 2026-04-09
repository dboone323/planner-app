//
// NetworkSecurityPolicy.swift
// PlannerAppCore
//

import Foundation

/// Policy for enforcing network security constraints.
public enum NetworkSecurityPolicy: Sendable {
    public static let pinnedDomains: Set<String> = [
        "api.plannerapp.io",
    ]

    /// Creates a URLSession configured with core security defaults.
    public static func makeSecureSession(delegate: URLSessionDelegate? = nil) -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
}
