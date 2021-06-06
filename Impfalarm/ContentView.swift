//
//  ContentView.swift
//  Impfalarm
//
//  Created by Jannik Feuerhahn on 04.06.21.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var logic:Logic
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollViewReader { proxy in
                    Form {
                        if let error = logic.error {
                            Section(header:Text("Fehler")) {
                                HStack {
                                    Text(error)
                                    Spacer()
                                    Image(systemName: "xmark.octagon")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        if logic.deniedPushAuth {
                            Section(header: Text("Berechtigung")) {
                                HStack {
                                    Text("Sie haben der App die Berechtigung verweigert Pushnachrichten zu empfangen.")
                                    Spacer()
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.yellow)
                                }
                                
                                Button(action: {
                                    logic.openPushSettings()
                                }, label: {
                                    Text("Einstellung öffnen")
                                })
                                
                            }
                        }
                        
                        if logic.saved {
                            Section(header: Text("Status")) {
                                HStack {
                                    Text("Deine Daten wurden gespeichert. Du wirst benachrichtigt, sobald ein Impftermin frei ist.")
                                    Spacer()
                                    Image(systemName: "checkmark.icloud")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        Section(header: Text("Nutzerdaten")) {
                            HStack {
                                Text("Postleitzahl")
                                Spacer()
                                TextField("12345", text: $logic.zip)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(DefaultTextFieldStyle())
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(logic.saved ? Color(UIColor(named: "DisabledColor")!) : .primary)
                                
                            }
                            Toggle("Alter über 60", isOn: $logic.ageOver60)
                                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.systemBlue)))
                        }.id(1)
                        .disabled(logic.saved)
                        
                        Section(header: Text("Benachrichtigungen")) {
                            Picker(selection: $logic.priorityIndex, label: Text("Frequenz")) {
                                ForEach(0 ..< logic.priorityOptions.count) {
                                    Text(logic.priorityOptions[$0])
                                }
                            }
                        }
                        .disabled(logic.saved)
                        
                        Section(header: Text("Impfstoffe")) {
                            Toggle("AstraZeneca", isOn: $logic.allowAstra)
                                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.systemBlue)))
                            Toggle("BioNTech", isOn: $logic.allowBiontech)
                                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.systemBlue)))
                            Toggle("Johnson & Johnson", isOn: $logic.allowJohnson)
                                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.systemBlue)))
                            Toggle("Moderna", isOn: $logic.allowModerna)
                                .toggleStyle(SwitchToggleStyle(tint: Color(UIColor.systemBlue)))
                        }
                        .disabled(logic.saved)
                        
                        Section {
                            if !logic.saved {
                                Button(action: {
                                    logic.subscribe()
                                    //Scroll to top
                                    proxy.scrollTo(1)
                                    UIApplication.shared.endEditing()
                                }) {
                                    Text("Benachrichtigung aktivieren")
                                }.disabled(logic.deniedPushAuth)
                            } else {
                                Button(action: {
                                    withAnimation {
                                        logic.unsubscribe()
                                        UIApplication.shared.endEditing()
                                    }
                                }, label: {
                                    Text("Benachrichtigung deaktivieren")
                                        .foregroundColor(.red)
                                })
                            }
                        }
                    }
                    .navigationBarTitle("Impfalarm")
                }
            }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                logic.checkForPushAuthorization()
            }.onAppear() {
                logic.checkForPushAuthorization()
            }
            
            if logic.loading {
                Rectangle()
                    .foregroundColor(.init(white: 0, opacity: 0.2))
                    .ignoresSafeArea()
                ProgressView("Lädt...")
            }
        }
    }
    
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            ContentView(logic: Logic())
        }
    }
}
