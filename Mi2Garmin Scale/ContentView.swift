import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @Environment(\.colorScheme) var colorScheme
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingSuccessAlert = false // Для отображения alert после отправки
    @State private var reminderTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var isNotificationSettingsExpanded = false
    @State private var isPressed = false // Для отслеживания состояния нажатия кнопки
    @State private var isSendButtonPressed = false // Для второй кнопки


    let keychainManager = KeychainManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .top, endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                Form {
                                       
                    Section(header: Text("Полученные данные с весов")) {
                        Text(bluetoothManager.receivedData == 0.00 ? "Ожидание данных..." : String(format: "%.2f", bluetoothManager.receivedData))
                    }
                    Section(header: Text("Введите ваши учетные данные Garmin")) {
                        TextField("Email", text: $email)
                            .padding()
                            .cornerRadius(8.0)
                        SecureField("Password", text: $password)
                            .padding()
                            .cornerRadius(8.0)
                    }
                    Section {
                        Button(action: {
                            // Действия при нажатии кнопки
                            saveCredentials()
                            sendDataToGarmin()
                        }) {
                            Text("Отправить данные в Garmin Connect")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(8.0)
                                .scaleEffect(isSendButtonPressed ? 0.95 : 1.0) // Изменение масштаба при нажатии
                                .animation(.easeInOut(duration: 0.2), value: isSendButtonPressed) // Анимация для плавности
                        }
                        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                            withAnimation {
                                self.isSendButtonPressed = pressing
                            }
                        }, perform: {})

                    }
                    DisclosureGroup("Настройки уведомлений", isExpanded: $isNotificationSettingsExpanded) {
                            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(WheelDatePickerStyle())
                        Button(action: {
                                            // Действие кнопки
                                            scheduleDailyReminder()
                                        }) {
                                            Text("Сохранить напоминание")
                                                .padding()
                                                .frame(maxWidth: .infinity)
                                                .foregroundColor(.white)
                                                .background(LinearGradient(gradient: Gradient(colors: [Color.green, Color.blue]), startPoint: .leading, endPoint: .trailing))
                                                .cornerRadius(8.0)
                                                .scaleEffect(isPressed ? 0.95 : 1.0) // Анимированное изменение размера
                                                .animation(.easeInOut(duration: 0.2), value: isPressed) // Анимация для плавности
                                        }
                                        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                                            withAnimation {
                                                self.isPressed = pressing
                                            }
                                        }, perform: {})
                                    
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
    func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Напоминание о взвешивании"
        content.body = "Не забудьте взвеситься сегодня утром!"
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("Ошибка при добавлении уведомления: \(error.localizedDescription)")
            }
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
