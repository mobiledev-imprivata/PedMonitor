//
//  Logger.swift
//  PedMonitor
//
//  Created by Jay Tucker on 12/19/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import Foundation

let newMessageNotificationName = "com.imprivata.PedMonitor.newMessage"

var dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "HH:mm:ss.SSS"
    return df
}()

func log(_ message: String) {
    let timestamp = dateFormatter.string(from: Date())
    let text = "[\(timestamp)] \(message)"
    print(text)
    NotificationCenter.default.post(name: Notification.Name(rawValue: newMessageNotificationName), object: nil, userInfo: ["text": text])
}
