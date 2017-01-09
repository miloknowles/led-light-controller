//
//  ViewController.swift
//  LED Light Control
//
//  Created by Milo Knowles, 2016.
//

// NOTES:
// 7/28/2016: For now, I have two tabs for the app in Main.storyboard. Later on, when I add in music effects, I will do so on the second tab. For now, it's just a blank page in the app.


import CoreBluetooth
import UIKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    //creating BLE objects
    var centralManager: CBCentralManager!
    var LEDLightPeripheral: CBPeripheral!
    
    //MARK: Properties
    @IBOutlet weak var redSliderBar: UISlider!
    @IBOutlet weak var greenSliderBar: UISlider!
    @IBOutlet weak var blueSliderBar: UISlider!
    @IBOutlet weak var lumenSliderBar: UISlider!

    @IBOutlet weak var colorDisplayButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var colorDisplay: UIImageView!
    
    @IBOutlet weak var mainView: UIView!
    
    var redValue: Float = 0.5
    var greenValue: Float = 0.5
    var blueValue: Float = 0.5
    var brightnessValue: Float = 1.0
    
    var stringToSend: NSString = "red"
    var RXCharacteristic: CBCharacteristic?
    var TXCharacteristic: CBCharacteristic?
    
    //creating a swipe recognizer for bluetooth refresh
    var swipeRecognizer = UISwipeGestureRecognizer()
    
    //MARK: Special Control Buttons (slow fade, fast fade, cut, flash)
    @IBAction func slowFadeButtonPressed(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            self.stringToSend = "slowFade"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    @IBAction func fastFadeButtonPressed(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            self.stringToSend = "fastFade"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    @IBAction func cutEffectButton(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            self.stringToSend = "cut"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }

    }
    
    @IBAction func flashEffectButton(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            self.stringToSend = "flash"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    
    //MARK: Preset Color Tile Buttons
    @IBAction func presetColorTile(_ sender: UIButton) {
            redValue = 0
            greenValue = 0
            blueValue = 0
            
            switch sender.tag { //each of the preset color tiles has an integer tag
            case 0:
                redValue = 1
            case 1:
                greenValue = 1
            case 2:
                blueValue = 1
            case 3:
                redValue = 0.588
                greenValue = 0.588
                blueValue = 0.588
            case 4:
                redValue = 1
                blueValue = 0.471
            case 5:
                redValue = 0.471
                blueValue = 1
            case 6:
                blueValue = 1
                greenValue = 1
            default:
                redValue = 0
                blueValue = 0
                greenValue = 0
            }
            //once all of the colors are updated, send them to the LEDs
            sendColorToLEDS()
        }
    
    
    
    //MARK: Slider Bars
    @IBAction func redSliderUpdated(_ sender: UISlider) {
        self.redValue = redSliderBar.value
        //update the color display to show the modified color
        updateColorDisplay()
    }
    
    @IBAction func greenSliderUpdated(_ sender: UISlider) {
        self.greenValue = greenSliderBar.value
        //update the color display to show the modified color
        updateColorDisplay()
    }
    
    @IBAction func blueSliderChanged(_ sender: UISlider) {
        self.blueValue = blueSliderBar.value
        //update the color display to show the modified color
        updateColorDisplay()
    }
    
    @IBAction func lumenSliderUpdated(_ sender: UISlider) {
        //update the brightness when the lumen slider is changed by 0.05 (prevents flooding the bluetooth TX)
        
        if abs(self.brightnessValue-lumenSliderBar.value)>0.05 {
            self.brightnessValue = lumenSliderBar.value
            //if the brightness value has changed, new colors should be sent to the LEDs
            sendColorToLEDS()
        }
        
        
    }
    
    
    //This function is called every time we want to send a new color command to the LEDs!
    func sendColorToLEDS() -> Void {
        if self.TXCharacteristic != nil {
            
            //break up into expressions because the expression was "too complex" before (see: http://stackoverflow.com/questions/29707622/bizarre-swift-compiler-error-expression-too-complex-on-a-string-concatenation )
            
            //scale the RGB values to a [0,255] range, and then dim based on the brightness fraction
            let ss1 = Int(255*self.redValue * self.brightnessValue)
            let ss2 = Int(255*self.greenValue * self.brightnessValue)
            let ss3 = Int(255*self.blueValue * self.brightnessValue)
            
            //convert the current stringToSend into NSData, then send it using the TXCharacteristic
            self.stringToSend = "\(ss1).\(ss2).\(ss3)" as NSString
            //print(self.stringToSend)
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    //when the custom color button is pressed, use the sendColorToLEDS function to send the commmand
    @IBAction func setColorButtonPressed(_ sender: UIButton) {
        sendColorToLEDS()
    }

    
    //UpdateColorDisplay is called whenever slider bars adjust the custom color
    // it changes the rectangular UI color display
    func updateColorDisplay() -> Void {
        self.colorDisplay.backgroundColor = UIColor(red: CGFloat(redValue), green: CGFloat(greenValue), blue: CGFloat(blueValue), alpha: 1)
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //get the initial slider values and update the color display to show them
        redValue = redSliderBar.value
        greenValue = greenSliderBar.value
        blueValue = blueSliderBar.value
        
        //update the color display initially
        updateColorDisplay()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        //set up the swipe gesture for resetting bluetooth
        self.mainView.addGestureRecognizer(swipeRecognizer)
        swipeRecognizer.direction = UISwipeGestureRecognizerDirection.down
        swipeRecognizer.addTarget(self, action: #selector(ViewController.screenSwiped))
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //whenever the screen is swiped, turn on and off the bluetooth to reconnect
    func screenSwiped() -> Void {
        self.statusLabel.text = "Reconnecting to bluetooth..."
        
        if self.TXCharacteristic != nil {
            //disconnect from the peripheral if necessary
            self.centralManager.cancelPeripheralConnection(self.LEDLightPeripheral)
        }
        
        //now search for peripherals (this will trigger the whole connection routine)
        findPeripherals(centralManager)
    
        
    }
    
    

    
    //MARK: Bluetooth Low Energy Stuff
    
    // Check status of BLE hardware
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //use the findPeripherals function
        findPeripherals(central)
    }
    
    func findPeripherals(_ central: CBCentralManager) {
        
        if #available(iOS 10.0, *) {
            if central.state == CBManagerState.poweredOn {
                // Scan for peripherals if BLE is turned on
                central.scanForPeripherals(withServices: nil, options: nil)
                self.statusLabel.text = "Searching for BLE Devices..."
            }
            else {
                // Can have different conditions for all states if needed - print generic message for now
                self.statusLabel.text = "Bluetooth off or not initialized!"
            }
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    // The didDiscoverPeripheral function is called every time a peripheral device is found
    func centralManager(_ centralManager: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        //get the name of the peripheral device
        let nameOfDeviceFound = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey) as? NSString
        
        // the Adafruit bluetooth module shows up as "UART"
        if (nameOfDeviceFound=="UART") {
            self.statusLabel.text = "Discovered LEDs!"
            
            // Stop scanning for more devices
            self.centralManager.stopScan()
            
            // Set the "UART" as the peripheral we want and establish connection
            self.LEDLightPeripheral = peripheral
            self.LEDLightPeripheral.delegate = self
            self.centralManager.connect(peripheral, options: nil)
            
        } else {
            self.statusLabel.text = "Could not find LEDs. Make sure they are turned on and within range."
        }
    
    }
    
    // This function is called when we connect to a peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.statusLabel.text = "Discovering peripheral services..."
        
        // upon connecting, check to see what services the peripheral offers
        peripheral.discoverServices(nil)
    }
    
    // Check through the services, if it is the one we want, then explore the characteristics of it
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        self.statusLabel.text = "Looking at peripheral services..."
        
        let desiredUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
        
        for service in peripheral.services! {
            let thisService = service as CBService
            if thisService.uuid == desiredUUID {
                // Discover characteristics of the UART service
                peripheral.discoverCharacteristics(nil, for: thisService)
                self.statusLabel.text = "Found UART Service!"
            }
        }
    }
    
    // Look for the TX and RX services of the UART service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        // update status label
        self.statusLabel.text = "Enabling TX and RX services..."
        
        // check the uuid of each characteristic to find config and data characteristics
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic //downcast as a CBChracteristic
            
            // check for RX characteristic (contains 00003)
            if thisCharacteristic.uuid == CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") {
                self.statusLabel.text = "Found RX characteristic!"
                self.RXCharacteristic = thisCharacteristic
                // Enable RX notification
                self.LEDLightPeripheral.setNotifyValue(true, for: thisCharacteristic)
            }
            
            // check for TX characteristic (contains 00002)
            if thisCharacteristic.uuid == CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") {
                self.statusLabel.text = "Found TX characteristic!"
                //print("Found TX characteristic!")
                self.TXCharacteristic = thisCharacteristic
                
                // Indicate that we've turned on the LED lights by changing their color to red (the initial value of stringToSend)
                let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
                self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)

            }
        }
        
    }
    

}

