import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var receivedMessage: String?
    
    private var centralManager: CBCentralManager!
    private var esp32Peripheral: CBPeripheral?
    private var dataCharacteristic: CBCharacteristic?
    
    private let serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914a")
    private let characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a3")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Computed property to check if we're connected
    var isConnected: Bool {
        return esp32Peripheral?.state == .connected
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScanning()
        } else {
            print("Bluetooth not available")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        esp32Peripheral = peripheral
        esp32Peripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        esp32Peripheral?.discoverServices([serviceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == characteristicUUID {
                    dataCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("Found data characteristic")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMessage = message
            }
        }
    }
    
    func reconnect() {
        // If we previously connected to a peripheral, try connecting again
        if let peripheral = esp32Peripheral, centralManager.state == .poweredOn {
            print("Attempting to reconnect to ESP32...")
            centralManager.connect(peripheral, options: nil)
        } else {
            // If no peripheral is known or Bluetooth isn't on, start scanning again
            print("No known peripheral or Bluetooth not powered on, starting scan...")
            startScanning()
        }
    }
    
    // Function to send a message to the ESP32
    func sendMessage(_ message: String) {
        guard let dataCharacteristic = dataCharacteristic else { return }
        let data = Data(message.utf8)
        esp32Peripheral?.writeValue(data, for: dataCharacteristic, type: .withResponse)
    }
    
    func sendDirection(_ maneuver: String, distance: Double) {
        
        let navigationCommand = NavigationCommand(maneuver: maneuver, distance: distance)
        
        do {
            let jsonData = try JSONEncoder().encode(navigationCommand)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Sending JSON: \(jsonString)")
                self.sendMessage(jsonString)
            }
        } catch {
            print("Failed to encode JSON: \(error)")
        }
        
    }
}
