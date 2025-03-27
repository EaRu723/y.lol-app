import Foundation

class LocalCredentialStore {
    private static let huxleyEmailKey = "huxleyEmail"
    private static let huxleyApiKeyKey = "huxleyApiKey"
    
    static func saveHuxleyCredentials(email: String, apiKey: String) {
        UserDefaults.standard.set(email, forKey: huxleyEmailKey)
        UserDefaults.standard.set(apiKey, forKey: huxleyApiKeyKey)
    }
    
    static func getHuxleyCredentials() -> (email: String?, apiKey: String?) {
        let email = UserDefaults.standard.string(forKey: huxleyEmailKey)
        let apiKey = UserDefaults.standard.string(forKey: huxleyApiKeyKey)
        return (email, apiKey)
    }
    
    static func clearHuxleyCredentials() {
        UserDefaults.standard.removeObject(forKey: huxleyEmailKey)
        UserDefaults.standard.removeObject(forKey: huxleyApiKeyKey)
    }
} 