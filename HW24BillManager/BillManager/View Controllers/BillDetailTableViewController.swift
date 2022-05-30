import UIKit

// MARK: - Classes
class BillDetailTableViewController: UITableViewController, UITextFieldDelegate {
    //MARK: - Private constants
    private let datePickerHeight = CGFloat(216)
    private let dueDateCellIndexPath = IndexPath(row: 2, section: 0)
    private let remindDateCellIndexPath = IndexPath(row:0, section: 1)
    
    // MARK: - Outlets
    @IBOutlet var payeeTextField: UITextField!
    @IBOutlet var amountTextField: UITextField!
    @IBOutlet var dueDateLabel: UILabel!
    @IBOutlet var dueDatePicker: UIDatePicker!
    
    @IBOutlet var remindStatusLabel: UILabel!
    @IBOutlet var remindSwitch: UISwitch!
    @IBOutlet var remindDatePicker: UIDatePicker!
    
    @IBOutlet var paidStatusLabel: UILabel!
    @IBOutlet var paidSwitch: UISwitch!
    @IBOutlet var paidDateLabel: UILabel!
    
    // MARK: - Properties
    var isDueDatePickerShown: Bool = false {
        didSet {
            dueDatePicker.isHidden = !isDueDatePickerShown
        }
    }
    var isRemindDatePickerShown: Bool = false {
        didSet {
            remindDatePicker.isHidden = !isRemindDatePickerShown
        }
    }
    
    var bill: Bill?
    var paidDate: Date?
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(tapGestureRecognizer)
        amountTextField.keyboardType = .decimalPad
        paidDateLabel.text = ""
        
        dueDatePicker.date = Calendar.current.startOfDay(for: Date()).addingTimeInterval(86399)
        updateDueDateUI()
        
        if let bill = bill {
            title = "Edit Bill"
            payeeTextField.text = bill.payee
            amountTextField.text = String(format: "%@", arguments: [(bill.amount ?? 0).formatted(.number.precision(.fractionLength(2)))])
            if let dueDate = bill.dueDate {
                dueDatePicker.date = dueDate
            }
            updateDueDateUI()
            remindSwitch.isOn = bill.hasReminder
            remindDatePicker.date = bill.remindDate ?? Date()
            updateRemindUI()
            paidSwitch.isOn = bill.isPaid
            paidDate = bill.paidDate
            updatePaymentUI()
            navigationItem.leftBarButtonItem = nil
        } else {
            title = "Add Bill"
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
        }
    }
    
    // MARK: - Objective Methods
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Methods
    func updateDueDateUI() {
        dueDateLabel.text = dueDatePicker.date.formatted(date: .numeric, time: .omitted)
        remindDatePicker.maximumDate = dueDatePicker.date
    }
    
    func updateRemindUI() {
        if remindSwitch.isOn {
            remindStatusLabel.text = remindDatePicker.date.formatted(date: .numeric, time: .shortened)
        } else {
            remindStatusLabel.text = "No"
        }
    }
    
    func updatePaymentUI() {
        if paidSwitch.isOn {
            paidStatusLabel.text = "Yes"
            paidDateLabel.text = Date().formatted(date: .abbreviated, time: .omitted)
        } else {
            paidStatusLabel.text = "No"
            paidDateLabel.text = ""
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == amountTextField {
            let text = (textField.text ?? "") as NSString
            let newText = text.replacingCharacters(in: range, with: string)
            if let _ = Double(newText) {
                return true
            }
            return newText.isEmpty
        } else {
            return true
        }
    }
    
    func presentNeedAuthorizationAlert() {
        let alert = UIAlertController(title: "Authorization Needed", message: "We can't set reminders for you without notification permissions. Please go to the iOS Settings app and grant us notification permissions if you wish to make use of reminders.", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var bill = self.bill ?? Database.shared.addBill()
        
        bill.payee = payeeTextField.text
        bill.amount = Double(amountTextField.text ?? "0") ?? 0.00
        bill.dueDate = dueDatePicker.date
        bill.paidDate = paidDate
        
        if remindSwitch.isOn {
            bill.schedulingReminders(date: remindDatePicker.date) { (updatedBill) in
                if updatedBill.notificationID == nil {
                    self.presentNeedAuthorizationAlert()
                }
                Database.shared.updateAndSave(updatedBill)
            }
        } else {
            bill.removingReminders()
            Database.shared.updateAndSave(bill)
        }
    }
    
    // MARK: - TableView Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch (indexPath.section, indexPath.row) {
        case (dueDateCellIndexPath.section, dueDateCellIndexPath.row):
            updateDueDateUI()
            
            if isDueDatePickerShown {
                isDueDatePickerShown = false
            } else if isRemindDatePickerShown {
                isRemindDatePickerShown = false
                isDueDatePickerShown = true
            } else {
                isDueDatePickerShown = true
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
            
        case (remindDateCellIndexPath.section, remindDateCellIndexPath.row):
            if isRemindDatePickerShown {
                isRemindDatePickerShown = false
            } else if isDueDatePickerShown {
                isDueDatePickerShown = false
                isRemindDatePickerShown = true
            } else {
                isRemindDatePickerShown = true
            }
            
            tableView.beginUpdates()
            tableView.endUpdates()
            
        default:
            break
        }
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch (indexPath.section, indexPath.row) {
        case (dueDateCellIndexPath.section, dueDateCellIndexPath.row + 1):
            if isDueDatePickerShown {
                return datePickerHeight
            } else {
                return 0
            }
        case (remindDateCellIndexPath.section, remindDateCellIndexPath.row + 1):
            if isRemindDatePickerShown {
                return datePickerHeight
            } else {
                return 0
            }
        default:
            return 44
        }
    }
    
    // MARK: - Actions
    @IBAction func remindSwitchChanged(_ sender: UISwitch) {
        
        if sender.isOn {
            isDueDatePickerShown = false
            isRemindDatePickerShown = true
        } else {
            isRemindDatePickerShown = false
        }
        
        tableView.beginUpdates()
        tableView.endUpdates()
        updateRemindUI()
    }
    
    @IBAction func paymentSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            paidDate = Date()
        } else {
            paidDate = nil
        }
        updatePaymentUI()
    }
    
    @IBAction func dueDatePickerValueChanged(_ sender: UIDatePicker) {
        updateDueDateUI()
    }
    
    @IBAction func remindDatePickerValueChanged(_ sender: UIDatePicker) {
        updateRemindUI()
    }
}

