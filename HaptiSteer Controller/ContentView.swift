import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()

    var body: some View {
        VStack {
            Text("HaptiSteer Controller")
                .font(.largeTitle)
                .padding()

            if let message = bleManager.receivedMessage {
                Text("Received Message: \(message)")
                    .padding()
            } else {
                Text("No messages from esp :(")
                    .padding()
            }

            // Button to send a message to ESP32
            Button(action: {
                bleManager.sendMessage("Hello from iPhone")
            }) {
                Text("Send Message to ESP32")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            bleManager.startScanning()
        }
    }
}
