//
//  ViewController.swift
//  Aerosentinel GCS
//
//  Created by Yassine Dehhani on 06/08/2023.
//

import Cocoa
import ORSSerial
import SwiftUI
import AppKit
//import Charts
import SceneKit

class ViewController: NSViewController{

    
    
    
    //--------------------------------------------------------------------------------------------------------
    
    //Variables Definitions
    
    var timer: Timer? // Timer variable to hold the reference to the timer
    var timerSerialSearch: Timer? // Timer variable to hold the reference to the timer
    
    private var serialPort: ORSSerialPort?
    private var connected = false // A flag to track the connection status
    private var sensor_readings_request = false // A flag to check the sensor reading request
    
    var countdownTimer: Timer?
    var countdownValue = 10 // 20 seconds
    var countUpTimer: Timer?
    var countUpValue = 1 // Initial value
    
    
    var roll: Double = 0.0
    var pitch: Double = 0.0
    var yaw: Double = 0.0
    
    
    @ObservedObject var stageController = Stage_Ctrl.shared // Use the shared instance
    
    
    let stages: [String] = ["Preflight","Countdown Sequence","Liftoff", "Propulsion End", "Apogee", "Parachute Deployment", "Reentry Phase","Landing"] // Add your stage labels here
    let minimum_progression_bar: Float = 0.478
    let maximum_progression_bar: Float = 0.723
    


    


    //--------------------------------------------------------------------------------------------------------
    // Outlets Declarations

    @IBOutlet weak var currentTimeBox: NSTextField!              // Current Time Field
    @IBOutlet weak var serialPortsSelection: NSComboBox!         // Serial Ports Combo Box Selection
    @IBOutlet weak var flightComputerStatus: NSLevelIndicator!   // Connection Status Level Indicator
    @IBOutlet weak var connectButton: NSButton!                  // Connection Button Title management
    @IBOutlet var flightControllerLogs: NSTextView!         // Flight Controller Text Field for Logging Purpose
    
        // Pressure Sensor Data
    @IBOutlet var pressionData: NSTextField!
        // Temperature Sensor Data
    @IBOutlet var temperatureData: NSTextField!
        // Sensor Fusion Data
    @IBOutlet var speed: NSTextField!
    @IBOutlet var altitude: NSTextField!
        // IMU Data Indicators
    

    @IBOutlet weak var RocketView: SCNView!
    @IBOutlet weak var SensorFusionIndicators: NSView!
    @IBOutlet weak var Telemetry: NSView!
    @IBOutlet weak var StageControl: NSView!
    //--------------------------------------------------------------------------------------------------------
    
    
    @IBOutlet weak var timeStamp: NSTextField!
    
    // Actions Declarations
    @IBAction func connectToSerial_btn(_ sender: NSButton) {
        if !connected {
            connectToSerialPort()
            sendStartCommand()
        } else {
            disconnectFromSerialPort()
        }
    }
    
    
    private func connectToSerialPort(){
        // Connect to the serial port
        let selectedPort = serialPortsSelection.stringValue
        if !selectedPort.isEmpty {
            serialPort = ORSSerialPort(path: "/dev/\(selectedPort)")
            serialPort?.baudRate = 115200
            serialPort?.delegate = self
            serialPort?.open()

        } else {
            showAlert(message: "Please select a serial port.")
        }
    }

    private func disconnectFromSerialPort(){
        // Disconnect from the serial port
        serialPort?.close()
        serialPort = nil
    }
    
    @IBAction func initialize_btn(_ sender: NSButton) {
        // Call sendCommand() with the command value 0
        sendCommand(command: 0)
        
        
    }

    @IBAction func launch_btn(_ sender: NSButton) {
        //Launch Procedure + Sensors Readings
        startCountdown()
    }
    
    @IBAction func abort_btn(_ sender: NSButton) {
        
        stopCount()
    }
    

    
    //--------------------------------------------------------------------------------------------------------
    // Function : ViewDidLoad -> Execute tasks when the application is opened
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        // 1: Load .usdz file
              let scene = SCNScene(named: "./Aerosentinel_Scene.scn")
        
        
        
              // Allow user to manipulate camera
        RocketView.allowsCameraControl = true
              // Show FPS logs and timming
        //RocketView.showsStatistics = true
              // Set scene settings
        RocketView.scene = scene
        
        
        
        let hostingController = HostingController(rootView: Level_Indicators())

        addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.frame = SensorFusionIndicators.bounds
        SensorFusionIndicators.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: SensorFusionIndicators.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: SensorFusionIndicators.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: SensorFusionIndicators.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: SensorFusionIndicators.bottomAnchor)
        ])
        
        
        
        let telemetryHostingController = TelemetryHostingController(rootView: Telemetry_Graphs())

        addChild(telemetryHostingController)
        telemetryHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        telemetryHostingController.view.frame = Telemetry.bounds
        Telemetry.addSubview(telemetryHostingController.view)

        NSLayoutConstraint.activate([
            telemetryHostingController.view.topAnchor.constraint(equalTo: Telemetry.topAnchor),
            telemetryHostingController.view.leadingAnchor.constraint(equalTo: Telemetry.leadingAnchor),
            telemetryHostingController.view.trailingAnchor.constraint(equalTo: Telemetry.trailingAnchor),
            telemetryHostingController.view.bottomAnchor.constraint(equalTo: Telemetry.bottomAnchor)
        ])
        
        
        let stage_Control_Controller = StageControl_Controller(rootView: Stage_Control())
        addChild(stage_Control_Controller)
        stage_Control_Controller.view.translatesAutoresizingMaskIntoConstraints = false
        stage_Control_Controller.view.frame = StageControl.bounds
        StageControl.addSubview(stage_Control_Controller.view)

        NSLayoutConstraint.activate([
            stage_Control_Controller.view.topAnchor.constraint(equalTo: StageControl.topAnchor),
            stage_Control_Controller.view.leadingAnchor.constraint(equalTo: StageControl.leadingAnchor),
            stage_Control_Controller.view.trailingAnchor.constraint(equalTo: StageControl.trailingAnchor),
            stage_Control_Controller.view.bottomAnchor.constraint(equalTo: StageControl.bottomAnchor)
        ])
        
        
  
        

        // Start the timer to update the current time every second (1000 milliseconds)
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateCurrentTime()
        }
        
        // Start the timer to update the serial ports every 2 seconds (2000 milliseconds)
        timerSerialSearch = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.populateSerialPortComboBox()
        }



        // Call the method to update the current time immediately
        updateCurrentTime()
        
        // Call the method to populate the combo box with available serial ports immediately
        populateSerialPortComboBox()
        
        // Do any additional setup after loading the view.
    }
    
    // Function : ViewDidLoad END
    //--------------------------------------------------------------------------------------------------------

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    //--------------------------------------------------------------------------------------------------------
    private func updateCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm:ss"

        // Get the current time in the desired format
        let currentTime = formatter.string(from: Date())

        // Set the current time in the text field
        currentTimeBox.stringValue = currentTime
    }
    //--------------------------------------------------------------------------------------------------------
    
    private func populateSerialPortComboBox() {
        // Clear any existing items in the combo box
        serialPortsSelection.removeAllItems()

        // Get a list of available serial ports (in macOS, they are usually located in /dev/)
        let serialPorts = getSerialPorts()

        // Add each serial port as an item in the combo box
        for port in serialPorts {
            serialPortsSelection.addItem(withObjectValue: port)
        }
    }
    
    //--------------------------------------------------------------------------------------------------------

    private func getSerialPorts() -> [String] {
        // Get a list of available serial ports (in macOS, they are usually located in /dev/)
        let fileManager = FileManager.default
        let devPath = "/dev"

        do {
            let files = try fileManager.contentsOfDirectory(atPath: devPath)
            return files.filter { $0.hasPrefix("tty.") }
        } catch {
            print("Error getting serial ports: \(error)")
            return []
        }
    }
    
    //--------------------------------------------------------------------------------------------------------

    func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    
    
    
    private func updateLogs(withReceivedData data: Data) {
        if let receivedString = String(data: data, encoding: .utf8) {
            let existingLogs = flightControllerLogs.textStorage
            // Append the received string to the existing text in the text view
            let newLogs = existingLogs?.length == 0 ? receivedString : (existingLogs?.string ?? "") + receivedString
            
            // Apply custom font size (8), text color (white), and text alignment (left) to the existing logs
            let fontSize: CGFloat = 8
            let textColor: NSColor = .white
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            let existingAttributes: [NSAttributedString.Key: Any] = [
                NSAttributedString.Key.font: NSFont.systemFont(ofSize: fontSize),
                NSAttributedString.Key.foregroundColor: textColor,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
            let attributedString = NSAttributedString(string: newLogs, attributes: existingAttributes)
            
            // Set the text of the text view with the updated font size and color
            flightControllerLogs.textStorage?.setAttributedString(attributedString)
            
            // Scroll to the end of the text view to show the latest data
            let endRange = NSRange(location: flightControllerLogs.string.count, length: 0)
            flightControllerLogs.scrollRangeToVisible(endRange)
        }
    }
    


    
    // Function to handle incoming data and store it in the arrays
    // 1  -> Acc_X  | 2 -> Acc_Y | 3 -> Acc_Z
    // 4  -> Gyro_X | 5 -> Gyro_Y | 6 -> Gyro_Z
    // 7  -> Roll   | 8 -> Pitch
    // 9  -> Temp_1
    // 10 -> Press  | 11 -> Temp_2
    // 12 -> Yaw
    private func handleIncomingData(withReceivedData data: Data) {
        if let receivedString = String(data: data, encoding: .utf8) {
            // Split the received data into lines
            let lines = receivedString.components(separatedBy: ";")
            
            for line in lines {
                // Split each line by comma to get datatype and value
                let components = line.components(separatedBy: ", ")
                if components.count == 2, let dataType = Int(components[0]), let value = Double(components[1]) {
                    // Check the datatype and store the value in the appropriate array
                    switch dataType {
                    case 1:
                        // Store Acceleration X value
                        DataSource.shared.accelerationArray.append(Model(reading_name: "Accel_x", value: value, time: currentTimeBox.stringValue))
                    case 2:
                        // Store Acceleration Y value
                        DataSource.shared.accelerationArray.append(Model(reading_name: "Accel_y", value: value, time: currentTimeBox.stringValue))
                    case 3:
                        // Store Acceleration Z value
                        DataSource.shared.accelerationArray.append(Model(reading_name: "Accel_z", value: value, time: currentTimeBox.stringValue))
                    case 4:
                        // Store Angular Rate X value
                        DataSource.shared.gyroscopeArray.append(Model(reading_name: "Gyro_x", value: value, time: currentTimeBox.stringValue))
                    case 5:
                        // Store Angular Rate Y value
                        DataSource.shared.gyroscopeArray.append(Model(reading_name: "Gyro_y", value: value, time: currentTimeBox.stringValue))
                    case 6:
                        // Store Angular Rate Z value
                        DataSource.shared.gyroscopeArray.append(Model(reading_name: "Gyro_z", value: value, time: currentTimeBox.stringValue))
                    case 7:
                        // Set Roll value
                        roll = value
                        updateRocketRotation()
                    case 8:
                        // Set Pitch Value
                        pitch = value
                        updateRocketRotation()
                    case 9:
                        // Set the Temperature Field
                        temperatureData.stringValue = String(Int(value)) + " °C"
                    case 10:
                        // Set the Pression Field
                        pressionData.stringValue = String(Int(value)) + " HPa"
                    case 12:
                        // Set Yaw Value
                        yaw = value
                        updateRocketRotation()
                    default:
                        break
                    }
                }
            }
        }
    }




    private func sendStartCommand() {
        // Check if the serial port is open and a valid command is provided
        guard let port = serialPort, port.isOpen else {
            flightComputerStatus.integerValue = 3
            print("Error: Serial port not open or invalid command.")
            return
        }

        // Convert the integer command to a string
        let commandString = "00$"

        // Convert the string command to data
        if let dataToSend = commandString.data(using: .utf8) {
            // Send the data to the serial port
            port.send(dataToSend)
        } else {
            print("Error: Unable to convert command to data.")
        }
    }
    
    
    private func sendCommand(command: Int) {
        // Check if the serial port is open and a valid command is provided
        guard let port = serialPort, port.isOpen, (0...255).contains(command) else {
            flightComputerStatus.integerValue = 3
            print("Error: Serial port not open or invalid command.")
            return
        }

        // Convert the integer command to a string
        let commandString = "\(command)"

        // Convert the string command to data
        if let dataToSend = commandString.data(using: .utf8) {
            // Send the data to the serial port
            port.send(dataToSend)
        } else {
            print("Error: Unable to convert command to data.")
        }
    }
    
    
    
    // Function to set the time to T-00:00:20
       func setCountdownTime() {
           timeStamp.stringValue = "T-00:00:20"
       }
       
       // Function to start the countdown and then the countdown + count up
       func startCountdown() {
           setCountdownTime()
           stageController.Stage = stages[1]
           sendCommand(command: 5)
           countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
               guard let self = self else {
                   timer.invalidate()
                   return
               }
               
               self.countdownValue -= 1
               if self.countdownValue >= 0 {
                   let seconds = self.countdownValue
                   self.timeStamp.stringValue = String(format: "T-00:00:%02d", seconds)
               } else {
                   sensor_readings_request = true
                   stageController.Stage = stages[2]
                   self.startCountUp()
                   timer.invalidate()
               }
           }
       }
       
       // Function to start counting upwards
       func startCountUp() {
           countUpTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
               guard let self = self else {
                   timer.invalidate()
                   return
               }
               
               self.timeStamp.stringValue = String(format: "T+00:00:%02d", self.countUpValue)
               self.countUpValue += 1
           }
       }
    
    
    func stopCount() {
           countdownTimer?.invalidate()
           countUpTimer?.invalidate()
       }
    
    
    func updateRocketRotation() {
        if let rocketNode = RocketView.scene?.rootNode.childNode(withName: "Rocket", recursively: true) {
            rocketNode.eulerAngles.x = CGFloat(degreesToRadians(pitch))
            rocketNode.eulerAngles.y = CGFloat(degreesToRadians(yaw))
            rocketNode.eulerAngles.z = CGFloat(degreesToRadians(roll))
            
            //print("Roll: \(rocketNode.eulerAngles.z) , Pitch: \(rocketNode.eulerAngles.x), Yaw: \(rocketNode.eulerAngles.y)")
        }
    }

    
    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * Double.pi / 180.0
    }

    
    
    
}







// Extension to handle ORSSerialPortDelegate methods
extension ViewController: ORSSerialPortDelegate {
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
            // Serial port connection successful, set the level indicator to 1
            flightComputerStatus.integerValue = 1
        
        
            // Change the button title to "Disconnect"
            connectButton.title = "Disconnect"
            connected = true // Set the flag to true after successful connection
            stageController.Stage = stages[0]
        
        }

        func serialPortWasClosed(_ serialPort: ORSSerialPort) {
            // Serial port connection closed, set the level indicator to 2
            flightComputerStatus.integerValue = 2
            // Change the button title back to "Connect"
            connectButton.title = "Connect"
            connected = false
            stageController.Stage = ""
        }

        func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
            // Serial port received new data, update logs
            if(!sensor_readings_request){
                updateLogs(withReceivedData: data)
            } else {
                handleIncomingData(withReceivedData: data)
            }
        }

        func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
            // Serial port was removed, handle the situation here if needed
            flightComputerStatus.integerValue = 2
            // Change the button title back to "Connect" if it was "Disconnect"
            if connectButton.title == "Disconnect" {
                connectButton.title = "Connect"
                connected = false
            }
            stageController.Stage = ""
        }

        func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
            // Serial port connection error, set the level indicator to 3
            flightComputerStatus.integerValue = 3
            print("Serial port connection error: \(error)")
            connectButton.title = "Connect" // Update the button title
            stageController.Stage = ""
        }
}







