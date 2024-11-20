import Security
import Foundation



enum KeychainError: Error {
    case unhandledError(status: OSStatus)
}

func saveApiKey(key:String) throws {
    let account = "com.example.keys.apikey" // Unique identifier for this API key
    let data = key.data(using: .utf8)!

    // Define the query for saving the API key
    let addQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecValueData as String: data
    ]
    
    // Delete any existing item with the same account to avoid duplication
    SecItemDelete(addQuery as CFDictionary)

    // Attempt to add the item to the Keychain
    let status = SecItemAdd(addQuery as CFDictionary, nil)
    print("Save API Key Status: \(status)")
    guard status == errSecSuccess else {
        throw KeychainError.unhandledError(status: status)
    }
}

// get and print api key
func getApiKey() -> String {
    let account = "com.example.keys.apikey"
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: account,
        kSecMatchLimit as String: kSecMatchLimitOne,
        kSecReturnData as String: true
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    
    if status == errSecSuccess {
        let data = item as! Data
        let key = String(data: data, encoding: .utf8)
        print("API Key: \(key!)")
        return key!
    } else{
        print("Error getting API key: \(status)")
        return ""
    }
}
