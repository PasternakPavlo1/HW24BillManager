import Foundation
import UserNotifications

// MARK: - Extensions
extension Bill {
    
    //MARK: - Properties
    static let notificationCategoryID = "NotificationReminder"
    
    var hasReminder: Bool {
        return (remindDate != nil)
    }
    
    var isPaid: Bool {
        return (paidDate != nil)
    }
    
    var formattedDueDate: String {
        let dateString: String
        
        if let dueDate = self.dueDate {
            dateString = dueDate.formatted(date: .numeric, time: .omitted)
        } else {
            dateString = ""
        }
        return dateString
    }
    
    // MARK: - Methods
    mutating func removingReminders() {
        guard let id = notificationID else {return}
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        notificationID = nil
        remindDate = nil
    }
    
    mutating func schedulingReminders(date: Date, completion: @escaping (Bill) -> ()) {
        var updatedBill = self
        
        updatedBill.removingReminders()
        
        authorizeIfNeeded { (granted) in
            guard granted else {
                DispatchQueue.main.async {
                    completion(updatedBill)
                }
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Bill Reminder"
            content.body = String(format: "%@ due to %@ on %@", arguments: [(updatedBill.amount ?? 0).formatted(.currency(code: "usd")), (updatedBill.payee ?? ""), updatedBill.formattedDueDate])
            content.categoryIdentifier = Bill.notificationCategoryID
            content.sound = UNNotificationSound.default
            
            let triggerDateComponents = Calendar.current.dateComponents([.second, .minute, .hour, .day, .month, .year], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
            
            let notificationID = UUID().uuidString
            
            let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error: Error?) in
                DispatchQueue.main.async {
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        updatedBill.notificationID = notificationID
                        updatedBill.remindDate = date
                    }
                    DispatchQueue.main.async {
                        completion(updatedBill)
                    }
                }
            })
        }
    }
    
    private func authorizeIfNeeded(completion: @escaping (Bool) -> ()) {
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                completion(true)
                
            case .notDetermined:
                notificationCenter.requestAuthorization(options: [.sound], completionHandler: { (granted, _) in
                    completion(granted)
                })
                
            case .ephemeral, .denied, .provisional:
                completion(false)
                
            @unknown default:
                completion(false)
            }
        }
    }
}

