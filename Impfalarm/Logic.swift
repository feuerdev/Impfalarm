//
//  Logic.swift
//  Impfalarm
//
//  Created by Jannik Feuerhahn on 06.06.21.
//

import SwiftUI

class Logic:ObservableObject {
    
    //User
    @Published var zip: String = ""
    @Published var ageOver60: Bool = false
    @Published var priorityIndex = 0
    
    @Published var allowBiontech: Bool = true
    @Published var allowJohnson: Bool = true
    @Published var allowModerna: Bool = true
    @Published var allowAstra: Bool = true
    
    //System
    @Published var saved = false
    @Published var error:String? = nil
    @Published var deniedPushAuth = false
    @Published var loading = false
    
    let priorityOptions:[String] = {
        var result = ["Ab einem freien Termin"]
        for index in 1...20 {
            result.append("Ab \(index*5) Terminen")
        }
        return result
    }()
    let subscribeUrlString = "http://127.0.0.1:3000/api/subscribe"
//    let subscribeUrlString = "http://185.250.248.164:3000/api/subscribe"
    let unsubscribeUrlString = "http://185.250.248.164:3000/api/unsubscribe"
    
    func openPushSettings() {
        if let bundleIdentifier = Bundle.main.bundleIdentifier, let appSettings = URL(string: UIApplication.openSettingsURLString + bundleIdentifier) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }
    
    func checkForPushAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .notDetermined {
                // Notification permission has not been asked yet, go for it!
            } else if settings.authorizationStatus == .denied {
                // Notification permission was previously denied, go to settings & privacy to re-enable
                DispatchQueue.main.async {
                    self.deniedPushAuth = true
                }
            } else if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    self.deniedPushAuth = false
                }
            }
        })
    }
    
    func unsubscribe() {
        guard let url = URL(string: self.unsubscribeUrlString) else {
            DispatchQueue.main.async {
                self.error = "Unerwarteter Fehler, bitte probieren Sie es noch später noch einmal."
            }
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "fcmToken") else {
            DispatchQueue.main.async {
                self.error = "Unerwarteter Fehler, bitte probieren Sie es noch später noch einmal."
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let parameters: [String: Any] = [
            "fcmToken": token
        ]
        request.httpBody = parameters.percentEncoded()
        DispatchQueue.main.async {
            self.loading = true
        }
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                DispatchQueue.main.async {
                    self.error = "Netzwerkfehler, bitte probieren Sie es noch später noch einmal."
                    self.loading = false
                }
                return
            }
            guard let response = response as? HTTPURLResponse,
                  response.statusCode == 200 else {
                DispatchQueue.main.async {
                    self.error = "Unerwarteter Fehler, bitte probieren Sie es noch später noch einmal."
                    self.loading = false
                }
                return
            }
            DispatchQueue.main.async {
                withAnimation {
                    self.loading = false
                    self.saved = false
                    self.error = nil
                }
            }
        }.resume()
    }
    
    func subscribe() {
        //Check if at least one vaccine is selected
        guard allowAstra || allowJohnson || allowModerna || allowBiontech else {
            DispatchQueue.main.async {
                self.error = "Bitte wähle mindestens einen Impfstoff aus."
            }
            return
        }
        
        let authOptions: UNAuthorizationOptions = [.alert, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions) { granted, error in
            guard error == nil else {
                self.error = "Unerwarteter Fehler, bitte probieren Sie es noch später noch einmal."
                return
            }
            
            if granted {
                guard let url = URL(string: self.subscribeUrlString) else {
                    self.error = "Unerwarteter Fehler, bitte probieren Sie es noch später noch einmal."
                    return
                }
                
                guard let token = UserDefaults.standard.string(forKey: "fcmToken") else {
                    self.error = "Unerwarteter Fehler, bitte probieren Sie es noch später noch einmal."
                    return
                }
                
                var request = URLRequest(url: url)
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                let parameters: [String: Any] = [
                    "fcmToken": token,
                    "ageOver60": self.ageOver60,
                    "zip": self.zip,
                    "minAppointments": self.convertFrequency(index: self.priorityIndex),
                    "allowBiontech": self.allowBiontech,
                    "allowJohnson": self.allowJohnson,
                    "allowModerna": self.allowModerna,
                    "allowAstra": self.allowAstra
                ]
                request.httpBody = parameters.percentEncoded()
                
                DispatchQueue.main.async {
                    self.loading = true
                }
                URLSession.shared.dataTask(with: request) { (data, response, error) in
                    guard error == nil else {
                        DispatchQueue.main.async {
                            self.error = "Netzwerkfehler, bitte probieren Sie es noch später noch einmal."
                            self.loading = false
                        }
                        return
                    }
                    guard let response = response as? HTTPURLResponse,
                          response.statusCode == 200 else {
                        DispatchQueue.main.async {
                            self.error = "Eingabefehler, bitte überprüfen Sie ihre Daten. Ist die Postleitzahl in Niedersachsen?"
                            self.loading = false
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            self.loading = false
                            self.saved = true
                            self.error = nil
                        }
                    }
                }.resume()
            } else {
                //Permission not granted
                DispatchQueue.main.async {
                    self.deniedPushAuth = true
                }
            }
        }
    }
    
    func convertFrequency(index:Int) -> Int {
        if index == 0 {
            return 1
        } else {
            return index * 5
        }
    }
}
