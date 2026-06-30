import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// Minimal loopback TCP server that captures the OAuth redirect code.
/// Binds to a random port on 127.0.0.1, accepts one connection, parses the code, returns it.
/// Requires `com.apple.security.network.server` entitlement in the macOS sandbox.
public actor OAuthLocalServer {
    public private(set) var port: UInt16 = 0
    private var serverFD: Int32 = -1

    public init() {}

    public func start() throws {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        guard fd >= 0 else { throw OAuthError.socketCreationFailed }

        var opt: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &opt, socklen_t(MemoryLayout<Int32>.size))

        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0                          // let the kernel choose
        addr.sin_addr = in_addr(s_addr: 0x0100007F) // 127.0.0.1 big-endian

        let bound = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0 else { close(fd); throw OAuthError.bindFailed }

        // Read back the assigned port
        var resolved = sockaddr_in()
        var len = socklen_t(MemoryLayout<sockaddr_in>.size)
        withUnsafeMutablePointer(to: &resolved) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                getsockname(fd, $0, &len)
            }
        }

        listen(fd, 1)

        self.serverFD = fd
        self.port = UInt16(bigEndian: resolved.sin_port)
    }

    /// Blocks (on a detached task) until one HTTP request arrives, then returns the `code` param.
    public func captureCode() async throws -> String {
        let fd = serverFD
        return try await Task.detached(priority: .userInitiated) {
            let clientFD = accept(fd, nil, nil)
            defer { close(clientFD) }
            guard clientFD >= 0 else { throw OAuthError.acceptFailed }

            var buf = [UInt8](repeating: 0, count: 8192)
            let n = recv(clientFD, &buf, buf.count - 1, 0)
            guard n > 0 else { throw OAuthError.readFailed }

            let request = String(bytes: buf[0..<n], encoding: .utf8) ?? ""
            guard let code = Self.extractCode(from: request) else {
                // Send a helpful error page so the browser doesn't hang
                Self.sendHTML(to: clientFD, "<h2>Error</h2><p>No auth code in redirect. Try connecting again.</p>")
                throw OAuthError.missingCode
            }

            Self.sendHTML(to: clientFD,
                """
                <html><body style='font-family:system-ui;text-align:center;padding:60px;color:#333'>
                <h2 style='color:#2F6BDB'>&#x2713; Winnow connected</h2>
                <p>Authentication successful — you can close this tab.</p>
                </body></html>
                """
            )
            return code
        }.value
    }

    public func stop() {
        if serverFD >= 0 { close(serverFD); serverFD = -1 }
    }

    // MARK: - Helpers (nonisolated so they're callable from the detached Task)

    private static func extractCode(from request: String) -> String? {
        guard let line = request.components(separatedBy: "\r\n").first,
              let path = line.components(separatedBy: " ").dropFirst().first,
              let comps = URLComponents(string: "http://localhost\(path)"),
              let code = comps.queryItems?.first(where: { $0.name == "code" })?.value
        else { return nil }
        return code
    }

    private static func sendHTML(to fd: Int32, _ html: String) {
        let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n\(html)"
        _ = send(fd, response, response.utf8.count, 0)
    }
}

public enum OAuthError: Error, LocalizedError {
    case socketCreationFailed
    case bindFailed
    case acceptFailed
    case readFailed
    case missingCode
    case pkceGenerationFailed
    case tokenExchangeFailed(String)
    case serverNotStarted

    public var errorDescription: String? {
        switch self {
        case .socketCreationFailed:        return "Could not open a local socket for OAuth redirect."
        case .bindFailed:                  return "Could not bind to a local port."
        case .acceptFailed:                return "Did not receive the OAuth redirect."
        case .readFailed:                  return "Could not read the OAuth redirect request."
        case .missingCode:                 return "No auth code in the OAuth redirect."
        case .pkceGenerationFailed:        return "PKCE code generation failed."
        case .tokenExchangeFailed(let m):  return "Token exchange failed: \(m)"
        case .serverNotStarted:            return "Local OAuth server was not started."
        }
    }
}
