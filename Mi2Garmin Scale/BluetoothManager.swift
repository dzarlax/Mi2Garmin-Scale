import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var receivedData = 0.00
    var centralManager: CBCentralManager!
    var activePeripheral: CBPeripheral?
    
    // UUID, используемый весами Xiaomi
    let serviceUUID = CBUUID(string: "181B")
    let characteristicUUID = CBUUID(string: "2A9C")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Если Bluetooth включен, начинаем сканирование
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth включен, начинаем сканирование")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            print("Bluetooth не активен")
        }
    }
    
    // Обработка результатов сканирования
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Обнаружено периферийное устройство: \(peripheral.name ?? "без имени")")
        self.centralManager.stopScan()
        
        self.activePeripheral = peripheral
        self.activePeripheral!.delegate = self
        
        // Подключаемся!
        self.centralManager.connect(self.activePeripheral!, options: nil)
    }
    
    // Обработчик успешного подключения
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Подключено к MiScale")
        peripheral.discoverServices([serviceUUID])
    }
    
    // Обработка события обнаружения служб
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services where service.uuid == serviceUUID {
                print("Служба найдена")
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    // Обработка обнаружения характеристик
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics where characteristic.uuid == characteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                print("Характеристика: \(characteristic)")
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    // Обработка обновления значений характеристик
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let scaleData = characteristic.value else {
            print("Отсутствует обновленное значение")
            return
        }
        
        let weightData = scaleData as NSData
        let lastByte = weightData.last!
        let multiplierByte = weightData[11]
        
        let weightValue = Int(lastByte)
        let multiplierValue = Int(multiplierByte)
        
        let weight = ((Double(weightValue) * 256) + Double(multiplierValue)) * 0.005
        DispatchQueue.main.async {
            // Отображение веса с точностью до двух знаков после запятой
            self.receivedData = weight
            print("Вес: \(self.receivedData)")
        }
    }
}
