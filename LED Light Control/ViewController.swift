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

    //notifications
    let colorNotification = Notification.Name(rawValue:"colorUpdate")
    
    //creating BLE objects
    var centralManager: CBCentralManager!
    var LEDLightPeripheral: CBPeripheral!
    
    //MARK: Properties

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var colorBookmarkedLabel: UILabel!
    var colorBookmarkedTimer = 0
    
    @IBOutlet weak var mainView: UIView!
    
    @IBOutlet weak var lightBulbView: UIImageView!
    
    @IBOutlet weak var redBar: UIView!
    @IBOutlet weak var greenBar: UIView!
    @IBOutlet weak var blueBar: UIView!
    @IBOutlet weak var dimmerBar: UIView!
    
    var redValue: Float = 0.5
    var greenValue: Float = 0.5
    var blueValue: Float = 0.5
    var brightnessValue: Float = 1.0
    
    var stringToSend: NSString = "red"
    var RXCharacteristic: CBCharacteristic?
    var TXCharacteristic: CBCharacteristic?
    
    var barDragProcess = 0 //0=off, 1=red bar, 2...4=dimmer bar
    var barDragLowBound: Float = 0.0
    var barDragUpperBound: Float = 0.0
    
    var bluetoothRefreshTapProcess = 0 //0=off, 1=tap on
    
    var refreshTimer = 0
    
    //creating a swipe recognizer for bluetooth refresh
    //var swipeRecognizer = UISwipeGestureRecognizer()
    
    //MARK: Special Control Buttons (slow fade, fast fade, cut, flash)
    @IBAction func slowFadeButtonPressed(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            print("SLOW FADE EFFECT")
            self.stringToSend = "slowFade"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    @IBAction func fastFadeButtonPressed(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            print("FAST FADE EFFECT")
            self.stringToSend = "fastFade"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    @IBAction func cutEffectButton(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            print("CUT EFFECT")
            self.stringToSend = "cut"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }

    }
    
    @IBAction func flashEffectButton(_ sender: UIButton) {
        if self.TXCharacteristic != nil {
            print("FLASH EFFECT")
            self.stringToSend = "flash"
            
            let dataToSend = self.stringToSend.data(using: String.Encoding.utf8.rawValue)!
            self.LEDLightPeripheral.writeValue(dataToSend, for: self.TXCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
        }
    }
    
    @IBAction func addColorButton(_ sender: UIButton) {
        var savedColors: NSMutableArray = []
        if UserDefaults.standard.object(forKey: "savedColors") != nil {
            savedColors = (UserDefaults.standard.object(forKey: "savedColors") as! NSArray).mutableCopy() as! NSMutableArray
        }
        let colorValues = [redValue,greenValue,blueValue,self.brightnessValue]
        savedColors.add(colorValues)
        UserDefaults.standard.set(savedColors, forKey: "savedColors")
        
        colorBookmarkedTimer = 120
        colorBookmarkedLabel.alpha = 1.0
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "colorSaved"), object: nil, userInfo: nil)
    }
    
    func update() {
        //throttles LED updates, avoids swamping arduino with inputs
        if barDragProcess != 0 {
            if refreshTimer <= 0 {
                refreshTimer = 10
                
                sendColorToLEDS()
            } else {
                refreshTimer -= 1
            }
        }
        
        //hides colorBookmarkedLabel after some time
        if colorBookmarkedTimer > 0 {
            colorBookmarkedTimer -= 1
            
            if colorBookmarkedTimer < 60 {
                colorBookmarkedLabel.alpha = CGFloat(Float(colorBookmarkedTimer)/Float(60.0))
            }
            
        } else if (colorBookmarkedTimer == 0) {
            colorBookmarkedTimer = -1
            colorBookmarkedLabel.alpha = 0
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

    
    //UpdateColorDisplay is called whenever slider bars adjust the custom color
    // it changes the rectangular UI color display
    func updateColorDisplay() -> Void {
        lightBulbView.tintColor = UIColor(red: CGFloat(((redValue*0.75)+0.25)*self.brightnessValue), green: CGFloat(((greenValue*0.75)+0.25)*self.brightnessValue), blue: CGFloat(((blueValue*0.75)+0.25)*self.brightnessValue), alpha: 1)
    }
    
    func catchNotification(notification:Notification) -> Void {
        if notification.name.rawValue == "colorUpdate" {
            let colorValues = notification.userInfo?["colorValues"] as? NSArray
            redValue = colorValues?.object(at: 0) as! Float
            greenValue = colorValues?.object(at: 1) as! Float
            blueValue = colorValues?.object(at: 2) as! Float
            self.brightnessValue = colorValues?.object(at: 3) as! Float
            
            let screenWidth = mainView.bounds.width
            let screenHeight = mainView.bounds.height
            
            redBar.frame = CGRect(x:0,y:180+((screenHeight-150-180)*CGFloat(1.0-redValue)),width:screenWidth/4.0,height:150+((screenHeight-150-150)*CGFloat(redValue)))
            greenBar.frame = CGRect(x:screenWidth*0.25,y:180+((screenHeight-150-180)*CGFloat(1.0-greenValue)),width:screenWidth/4.0,height:150+((screenHeight-150-150)*CGFloat(greenValue)))
            blueBar.frame = CGRect(x:screenWidth*0.5,y:180+((screenHeight-150-180)*CGFloat(1.0-blueValue)),width:screenWidth/4.0,height:150+((screenHeight-150-150)*CGFloat(blueValue)))
            dimmerBar.frame = CGRect(x:screenWidth*0.75,y:180+((screenHeight-150-180)*CGFloat(1.0-self.brightnessValue)),width:screenWidth/4.0,height:150+((screenHeight-150-150)*CGFloat(self.brightnessValue)))
            
            updateColorDisplay()
            sendColorToLEDS()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //setting up notification listeners
        NotificationCenter.default.addObserver(forName:colorNotification, object:nil, queue:nil, using:catchNotification)
        
        //get the initial slider values and update the color display to show them
        redValue = 1.0
        greenValue = 0
        blueValue = 0
        
        let lbimage = UIImage(named: "lightbulb.png")!.withRenderingMode(.alwaysTemplate)
        lightBulbView.image = lbimage
        
        //update the color display initially
        updateColorDisplay()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        //set up the swipe gesture for resetting bluetooth
        /*self.mainView.addGestureRecognizer(swipeRecognizer)
        swipeRecognizer.direction = UISwipeGestureRecognizerDirection.down
        swipeRecognizer.addTarget(self, action: #selector(ViewController.screenSwiped))*/
        
        //setting bar positions & width
        let screenWidth = mainView.bounds.width
        let screenHeight = mainView.bounds.height
        redBar.frame = CGRect(x:0,y:180,width:screenWidth/4.0,height:screenHeight-150)
        greenBar.frame = CGRect(x:screenWidth*0.25,y:screenHeight-150,width:screenWidth/4.0,height:150)
        blueBar.frame = CGRect(x:screenWidth*0.5,y:screenHeight-150,width:screenWidth/4.0,height:150)
        dimmerBar.frame = CGRect(x:screenWidth*0.75,y:180,width:screenWidth/4.0,height:screenHeight-150)
        
        barDragUpperBound = Float(screenHeight)-150.0
        barDragLowBound = 180.0
        
        _ = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //turn on and off the bluetooth to reconnect
    func refreshBluetooth() {
        self.statusLabel.text = "Reconnecting to bluetooth..."
        
        if self.TXCharacteristic != nil {
            //disconnect from the peripheral if necessary
            self.centralManager.cancelPeripheralConnection(self.LEDLightPeripheral)
        }
        
        //now search for peripherals (this will trigger the whole connection routine)
        findPeripherals(centralManager)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firstTouch:UITouch = touches.first! as UITouch
        if Float(firstTouch.location(in: mainView).y) > barDragLowBound && Float(firstTouch.location(in: mainView).y) < barDragUpperBound { //valid bar drag start
            
            //assigns region to touch
            let touchX = Float(firstTouch.location(in: mainView).x)
            var touchY = Float(firstTouch.location(in: mainView).y)
            let screenWidth = Float(mainView.bounds.width)
            let screenHeight = mainView.bounds.height
            if touchX < screenWidth*0.25 {
                barDragProcess = 1
            } else if touchX < screenWidth*0.5 {
                barDragProcess = 2
            } else if touchX < screenWidth*0.75 {
                barDragProcess = 3
            } else if touchX <= screenWidth {
                barDragProcess = 4
            }
            
            if barDragProcess == 1 { //red bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                redBar.frame = CGRect(x:0,y:CGFloat(touchY),width:CGFloat(screenWidth)/4.0,height:screenHeight-CGFloat(touchY))
                redValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            } else if barDragProcess == 2 { //green bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                greenBar.frame = CGRect(x:CGFloat(screenWidth)*0.25,y:CGFloat(touchY),width:CGFloat(screenWidth)/4.0,height:screenHeight-CGFloat(touchY))
                greenValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            } else if barDragProcess == 3 { //blue bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                blueBar.frame = CGRect(x:CGFloat(screenWidth)*0.5,y:CGFloat(touchY),width:CGFloat(screenWidth)/4.0,height:screenHeight-CGFloat(touchY))
                blueValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            } else if barDragProcess == 4 { //dimmer bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                dimmerBar.frame = CGRect(x:CGFloat(screenWidth)*0.75,y:CGFloat(touchY),width:CGFloat(screenWidth)/4.0,height:screenHeight-CGFloat(touchY))
                
                self.brightnessValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            }
            updateColorDisplay()
        } else if Float(firstTouch.location(in: mainView).y) >= barDragUpperBound && bluetoothRefreshTapProcess != 1 { //valid bluetooth refresh tap
            bluetoothRefreshTapProcess = 1
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firstTouch:UITouch = touches.first! as UITouch
        var touchY = Float(firstTouch.location(in: mainView).y)
        
        if barDragProcess != 0 {
            let screenWidth = mainView.bounds.width
            let screenHeight = mainView.bounds.height
            
            if barDragProcess == 1 { //red bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                redBar.frame = CGRect(x:0,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                redValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                //sendColorToLEDS()
            } else if barDragProcess == 2 { //green bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                greenBar.frame = CGRect(x:screenWidth*0.25,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                greenValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                //sendColorToLEDS()
            } else if barDragProcess == 3 { //blue bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                blueBar.frame = CGRect(x:screenWidth*0.5,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                blueValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                //sendColorToLEDS()
            } else if barDragProcess == 4 { //dimmer bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                dimmerBar.frame = CGRect(x:screenWidth*0.75,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                self.brightnessValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                //sendColorToLEDS()
            }
            updateColorDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let firstTouch:UITouch = touches.first! as UITouch
        var touchY = Float(firstTouch.location(in: mainView).y)
        
        if barDragProcess != 0 {
            let screenWidth = mainView.bounds.width
            let screenHeight = mainView.bounds.height
            
            if barDragProcess == 1 { //red bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                redBar.frame = CGRect(x:0,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                redValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            } else if barDragProcess == 2 { //green bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                greenBar.frame = CGRect(x:screenWidth*0.25,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                greenValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            } else if barDragProcess == 3 { //blue bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                blueBar.frame = CGRect(x:screenWidth*0.5,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                blueValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            } else if barDragProcess == 4 { //dimmer bar
                if touchY > barDragUpperBound {
                    touchY = barDragUpperBound
                } else if touchY < barDragLowBound {
                    touchY = barDragLowBound
                }
                dimmerBar.frame = CGRect(x:screenWidth*0.75,y:CGFloat(touchY),width:screenWidth/4.0,height:screenHeight-CGFloat(touchY))
                self.brightnessValue = 1.0+Float(barDragLowBound-touchY)/Float(barDragUpperBound-barDragLowBound)
                sendColorToLEDS()
            }
            updateColorDisplay()
        }
        
        barDragProcess = 0
        
        if bluetoothRefreshTapProcess != 0 {
            refreshBluetooth()
        }
        
        bluetoothRefreshTapProcess = 0
    }
    
    func getColorUpdate(redValueIn: Float, greenValueIn: Float, blueValueIn: Float, alphaValueIn: Float) {
        redValue = redValueIn
        greenValue = greenValueIn
        blueValue = blueValueIn
        self.brightnessValue = alphaValueIn
        print("COLOR UPDATE")
        
        /*
 
         redBar.frame = CGRect(x:0,y:180,width:screenWidth/4.0,height:screenHeight-150)
         greenBar.frame = CGRect(x:screenWidth*0.25,y:screenHeight-150,width:screenWidth/4.0,height:150)
         blueBar.frame = CGRect(x:screenWidth*0.5,y:screenHeight-150,width:screenWidth/4.0,height:150)
         dimmerBar.frame = CGRect(x:screenWidth*0.75,y:180,width:screenWidth/4.0,height:screenHeight-150)
         
        */
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

