import KeychainSwift

class KeychainManager {
    private let keychain = KeychainSwift()
    
    func savePassword(_ password: String, forAccount account: String) {
        keychain.set(password, forKey: account)
    }
    
    func getPassword(forAccount account: String) -> String? {
        return keychain.get(account)
    }
    
    func saveEmail(_ email: String) {
        keychain.set(email, forKey: "userEmail")
    }
    
    func getEmail() -> String? {
        return keychain.get("userEmail")
    }
}
