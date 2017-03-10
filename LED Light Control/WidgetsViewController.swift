//
//  WidgetsViewController.swift
//  LED Light Control
//
//  Created by Magnus Johnson on 3/10/17.
//  Copyright © 2017 Grassy Knoll Development. All rights reserved.
//

import UIKit

class TableViewCellCustom2: UITableViewCell {
    @IBOutlet weak var widgetIcon: UIImageView!
    @IBOutlet weak var widgetTitle: UILabel!
    @IBOutlet weak var widgetSwitch: UISwitch!
}

class WidgetsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var mainTableView: UITableView?
    
    var activeWidget:Int = -1
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "td2", for: indexPath) as! TableViewCellCustom2
        if indexPath.row == 0 {
            cell.widgetTitle.text = "Weather Indication"
            cell.widgetIcon.image = UIImage.init(named: "sun.png")
            cell.widgetSwitch.isEnabled = true
        } else if indexPath.row == 1 {
            cell.widgetTitle.text = "Microphone Amplitude"
            cell.widgetIcon.image = UIImage.init(named: "microphone.png")
        } else if indexPath.row == 2 {
            cell.widgetTitle.text = "Music BPM Synchronization"
            cell.widgetIcon.image = UIImage.init(named: "musicnote.png")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mainTableView?.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
    }
    
    func update() {
        
    }
    
    func catchNotification(notification:Notification) -> Void {
        /*if notification.name.rawValue == "colorSaved" {
            
        }*/
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //setting up notification listeners
        //NotificationCenter.default.addObserver(forName:colorSavedNotification, object:nil, queue:nil, using:catchNotification)
        
        _ = Timer.scheduledTimer(timeInterval: 1.0/60.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true);
    }
    
    override func viewWillAppear(_ animated: Bool) {
        mainTableView?.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
