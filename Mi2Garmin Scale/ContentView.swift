import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSuccessAlert = false // Для отображения alert после отправки
    
    let keychainManager = KeychainManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Введите ваши данные").foregroundColor(.white)) {
                        TextField("Email", text: $email)
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(8.0)
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.5))
                            .cornerRadius(8.0)
                    }
                    .foregroundColor(.white)
                    
                    Section(header: Text("Полученные данные с Bluetooth").foregroundColor(.white)) {
                        Text(bluetoothManager.receivedData == 0.00 ? "Ожидание данных..." : String(format: "%.2f", bluetoothManager.receivedData))
                            .foregroundColor(.white)
                    }
                    
                    Section {
                        Button(action: {
                            saveCredentials()
                            sendDataToGarmin()
                        }) {
                            Text("Отправить данные в Garmin Connect")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(8.0)
                        }
                    }
                }
            }
            .navigationBarTitle("Mi2Garmin", displayMode: .inline)
            .onAppear {
                loadCredentials()
            }
            .alert("Данные успешно отправлены", isPresented: $showingSuccessAlert) {
                Button("OK") { }
            }
        }

    }
    
    func saveCredentials() {
        keychainManager.saveEmail(email)
        keychainManager.savePassword(password, forAccount: email)
    }
    
    func loadCredentials() {
        if let loadedEmail = keychainManager.getEmail(),
           let loadedPassword = keychainManager.getPassword(forAccount: loadedEmail) {
            email = loadedEmail
            password = loadedPassword
        }
    }

    func sendDataToGarmin() {
        let payload = [
            "timeStamp": -1,
            "weight": bluetoothManager.receivedData,
            "email": email,
            "password": password,
        ] as [String : Any]

        guard let url = URL(string: "https://frog01-20364.wykr.es/upload") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "accept")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Failed to serialize JSON")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Request error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else { return }
            DispatchQueue.main.async {
                self.showingSuccessAlert = true
            }
        }.resume()
    }
}

// Предполагается, что KeychainManager уже реализован с методами saveEmail, savePassword, getEmail, и getPassword.

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
