import Foundation
import Security

public struct KeychainStore: Sendable {
    private let service: String

    public init(service: String = "com.keranm.winnow") {
        self.service = service
    }

    public func setData(_ data: Data, forKey key: String) throws {
        let query: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  service,
            kSecAttrAccount:  key
        ]
        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData] = data
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.write(status) }
    }

    public func getData(forKey key: String) throws -> Data? {
        let query: [CFString: Any] = [
            kSecClass:        kSecClassGenericPassword,
            kSecAttrService:  service,
            kSecAttrAccount:  key,
            kSecReturnData:   true,
            kSecMatchLimit:   kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError.read(status)
        }
        return data
    }

    public func delete(forKey key: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

public enum KeychainError: Error, LocalizedError {
    case write(OSStatus)
    case read(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .write(let s): return "Keychain write failed (\(s))"
        case .read(let s):  return "Keychain read failed (\(s))"
        }
    }
}
