import UIKit

class TableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var mainTableView: UITableView?
    
    var savedColors: NSMutableArray = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if UserDefaults.standard.object(forKey: "savedColors") != nil {
            savedColors = (UserDefaults.standard.object(forKey: "savedColors") as! NSArray).mutableCopy() as! NSMutableArray
            return savedColors.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "td")
        //cell.textLabel?.text = items[indexPath.row]
        
        if savedColors.count-1 >= indexPath.row {
            let colorValues = savedColors.object(at: indexPath.row) as! NSArray
            let redValue = colorValues.object(at: 0) as! Float
            let greenValue = colorValues.object(at: 1) as! Float
            let blueValue = colorValues.object(at: 2) as! Float
            let alphaValue = colorValues.object(at: 3) as! Float
            
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            // handle delete (by removing the data from your array and updating the tableview)
            savedColors.removeObject(at: indexPath.row)
            UserDefaults.standard.set(savedColors, forKey: "savedColors")
            mainTableView?.deleteRows(at: [indexPath], with: UITableViewRowAnimation.right)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        mainTableView?.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
