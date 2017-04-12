import UIKit

class TableViewCellCustom1: UITableViewCell {
    @IBOutlet weak var celllabel: UILabel!
    @IBOutlet weak var cellContentView: UIView!
}

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var mainTableView: UITableView?
    
    @IBOutlet weak var playPauseButton: UIButton?
    @IBOutlet weak var flashFadeToggleButton: UIButton?
    
    let colorSavedNotification = Notification.Name(rawValue:"colorSaved")
    
    var savedColors: NSMutableArray = []
    
    var activeRow = 0 //-1=none,0+ = row index
    var activeRowShineTimer:Float = 0
    var activeRowTimer = 0
    var activeRowTimerMax = 80
    var activeRowTimerMaxSlow = 220
    var colorRotationActive = false
    
    var flashModeColorRotation = 0 //0=flash, 1=fade, 2=fastfade
    
    @IBAction func toggleFadeFlash() {
        flashModeColorRotation += 1
        if flashModeColorRotation > 2 {
            flashModeColorRotation = 0
        }
        
        //updates UI & vars based on current mode
        if flashModeColorRotation == 0 {
            flashFadeToggleButton?.setImage(UIImage(named: "button_flash.png"), for: .normal)
        } else if flashModeColorRotation == 1 {
            flashFadeToggleButton?.setImage(UIImage(named: "button_fastfade.png"), for: .normal)
        } else if flashModeColorRotation == 2 {
            flashFadeToggleButton?.setImage(UIImage(named: "button_slowfade.png"), for: .normal)
        }
    }
    
    @IBAction func editToggle() {
        if mainTableView?.isEditing == true {
            mainTableView?.isEditing = false
        } else {
            if savedColors.count > 0 {
                mainTableView?.isEditing = true
                
                if colorRotationActive == true {
                    colorRotationActive = false
                    
                    playPauseButton?.setImage(UIImage(named: "button_play.png"), for: .normal)
                }
            }
        }
    }
    
    @IBAction func playPauseColorRotation() {
        if colorRotationActive == false {
            if savedColors.count > 0 {
                colorRotationActive = true
                
                playPauseButton?.setImage(UIImage(named: "button_pause.png"), for: .normal)
            }
        } else {
            colorRotationActive = false
            
            playPauseButton?.setImage(UIImage(named: "button_play.png"), for: .normal)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if UserDefaults.standard.object(forKey: "savedColors") != nil {
            savedColors = (UserDefaults.standard.object(forKey: "savedColors") as! NSArray).mutableCopy() as! NSMutableArray
            return savedColors.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "td", for: indexPath) as! TableViewCellCustom1
        //cell.textLabel?.text = items[indexPath.row]
        
        if savedColors.count-1 >= indexPath.row {
            let colorValues = savedColors.object(at: indexPath.row) as! NSArray
            let redValue = colorValues.object(at: 0) as! Float
            let greenValue = colorValues.object(at: 1) as! Float
            let blueValue = colorValues.object(at: 2) as! Float
            let alphaValue = colorValues.object(at: 3) as! Float
            
            //cell.cellContentView.backgroundColor = UIColor.init(colorLiteralRed: redValue*alphaValue, green: greenValue*alphaValue, blue: blueValue*alphaValue, alpha: 1.0)
            cell.backgroundColor = UIColor.init(colorLiteralRed: redValue*alphaValue, green: greenValue*alphaValue, blue: blueValue*alphaValue, alpha: 1.0)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mainTableView?.deselectRow(at: indexPath, animated: true)
        
        //send color data to ViewController
        let colorValues = savedColors.object(at: indexPath.row) as! NSArray
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "colorUpdate"), object: nil, userInfo: ["colorValues":colorValues])
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let data1 = savedColors.object(at: sourceIndexPath.row)
        let newSavedColors: NSMutableArray = savedColors.mutableCopy() as! NSMutableArray
        
        newSavedColors.removeObject(at: sourceIndexPath.row)
        newSavedColors.insert(data1, at: destinationIndexPath.row)
        
        savedColors = newSavedColors
        UserDefaults.standard.set(savedColors, forKey: "savedColors")
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            //turns color rotation off
            if colorRotationActive == true {
                colorRotationActive = false
                
                playPauseButton?.setImage(UIImage(named: "button_play.png"), for: .normal)
            }
            
            // handle delete (by removing the data from your array and updating the tableview)
            savedColors.removeObject(at: indexPath.row)
            UserDefaults.standard.set(savedColors, forKey: "savedColors")
            mainTableView?.deleteRows(at: [indexPath], with: UITableViewRowAnimation.right)
            
            UserDefaults.standard.synchronize()
        }
    }
    
    func update() {
        if colorRotationActive == true {
            if activeRow == -1 {
                activeRow = 0
                activeRowTimer = 0
                
                //send color data to ViewController
                let colorValues = savedColors.object(at: activeRow) as! NSArray
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "colorUpdate"), object: nil, userInfo: ["colorValues":colorValues])
                
                for row in 0..<mainTableView!.numberOfRows(inSection: 0) {
                    let cell:TableViewCellCustom1 = mainTableView?.cellForRow(at: IndexPath.init(row: row, section: 0)) as! TableViewCellCustom1
                    
                    if row == activeRow {
                        cell.celllabel!.alpha = 1.0
                    } else {
                        cell.celllabel!.alpha = 0.0
                    }
                }
            }
            
            activeRowTimer += 1
            var timerMax = activeRowTimerMax
            if flashModeColorRotation == 2 {
                timerMax = activeRowTimerMaxSlow
            }
            if activeRowTimer > timerMax {
                activeRowTimer = 0
                
                activeRow += 1
                
                if activeRow > (mainTableView?.numberOfRows(inSection: 0))!-1 {
                    activeRow = 0
                }
                
                //send color data to ViewController
                let colorValues = savedColors.object(at: activeRow) as! NSArray
                if flashModeColorRotation == 0 { //flash
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "colorUpdate"), object: nil, userInfo: ["colorValues":colorValues])
                } else if flashModeColorRotation == 1 { //fast fade
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "colorUpdateFastFade"), object: nil, userInfo: ["colorValues":colorValues])
                } else if flashModeColorRotation == 2 { //slow fade
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "colorUpdateSlowFade"), object: nil, userInfo: ["colorValues":colorValues])
                }
                
                for row in 0..<mainTableView!.numberOfRows(inSection: 0) {
                    let cell:TableViewCellCustom1 = mainTableView?.cellForRow(at: IndexPath.init(row: row, section: 0)) as! TableViewCellCustom1
                    
                    if row == activeRow {
                        cell.celllabel!.alpha = 1.0
                    } else {
                        cell.celllabel!.alpha = 0.0
                    }
                }
            }
        } else {
            if activeRow != -1 {
                activeRow = -1
                
                for row in 0..<mainTableView!.numberOfRows(inSection: 0) {
                    let cell:TableViewCellCustom1 = mainTableView?.cellForRow(at: IndexPath.init(row: row, section: 0)) as! TableViewCellCustom1
                    cell.celllabel!.alpha = 0.0
                }
            }
        }
        
        if activeRow != -1 {
            
            activeRowShineTimer += 1.0
            if activeRowShineTimer > 70.0 {
                activeRowShineTimer = 0
            }
            
            let selectedCell: TableViewCellCustom1 = (mainTableView?.cellForRow(at: IndexPath.init(row: activeRow, section: 0))) as! TableViewCellCustom1
            selectedCell.celllabel.textColor = UIColor.init(white: CGFloat((sinf((activeRowShineTimer/35.0)*Float(M_PI))+1.0)/2.0), alpha: 1.0)
        }
    }
    
    func catchNotification(notification:Notification) -> Void {
        if notification.name.rawValue == "colorSaved" {
            mainTableView?.reloadData()
            
            for row in 0..<mainTableView!.numberOfRows(inSection: 0) {
                let cell:TableViewCellCustom1 = mainTableView?.cellForRow(at: IndexPath.init(row: row, section: 0)) as! TableViewCellCustom1
                
                if row == activeRow {
                    cell.celllabel!.alpha = 1.0
                } else {
                    cell.celllabel!.alpha = 0.0
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //setting up notification listeners
        NotificationCenter.default.addObserver(forName:colorSavedNotification, object:nil, queue:nil, using:catchNotification)
        
        _ = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        mainTableView?.reloadData()
        
        for row in 0..<mainTableView!.numberOfRows(inSection: 0) {
            let cell:TableViewCellCustom1 = mainTableView?.cellForRow(at: IndexPath.init(row: row, section: 0)) as! TableViewCellCustom1
            
            if row == activeRow {
                cell.celllabel!.alpha = 1.0
            } else {
                cell.celllabel!.alpha = 0.0
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
