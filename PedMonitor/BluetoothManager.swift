//
//  BluetoothManager.swift
//  PedMonitor
//
//  Created by Jay Tucker on 12/19/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit
import CoreBluetooth

protocol BluetoothManagerDelegate {
    func readMotionData(interval: TimeInterval, completion: @escaping (String) -> Void)
}

struct Constants {
    static let serviceUUID                     = CBUUID(string: "B6108A9B-BF75-456B-8DCB-6942F2A3E5BA")
    static let setIntervalCharacteristicUUID   = CBUUID(string: "AB519B66-6215-48D8-8727-4D41FB35DA8F")
    static let getMotionDataCharacteristicUUID = CBUUID(string: "9D5F61B3-23E9-4812-8AF3-9536B9ADAC46")
    
    static let restoreIdentiferKey = "com.imprivata.pedmonitor.restoreIdentiferKey"
}

final class BluetoothManager: NSObject {
    
    var delegate:BluetoothManagerDelegate?
    
    private var service: CBMutableService = {
        let service = CBMutableService(type: Constants.serviceUUID, primary: true)
        let setIntervalCharacteristic = CBMutableCharacteristic(type: Constants.setIntervalCharacteristicUUID, properties: .write, value: nil, permissions: .writeable)
        let getMotionDataCharacteristic = CBMutableCharacteristic(type: Constants.getMotionDataCharacteristicUUID, properties: .read, value: nil, permissions: .readable)
        service.characteristics = [setIntervalCharacteristic, getMotionDataCharacteristic]
        return service
    }()
    
    private var isServiceInitialized = false
    
    private var peripheralManager: CBPeripheralManager?
    
    private var interval: TimeInterval = 10.0
    private var uiBackgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    
    func startAdvertising() {
        log("startAdvertising")
        guard peripheralManager == nil else { return }
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionRestoreIdentifierKey: Constants.restoreIdentiferKey])
    }
    
    func stopAdvertising() {
        log("stopAdvertising")
        guard peripheralManager == peripheralManager else { return }
        peripheralManager?.stopAdvertising()
        self.peripheralManager = nil
    }
    
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    
    func peripheralManager(_ peripheral: CBPeripheralManager, willRestoreState dict: [String : Any]) {
        let message = "peripheralManager willRestoreState"
        log(message)
        if let service = (dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService])?.first {
            log("found service to restore")
            self.service = service
            isServiceInitialized = true
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        var caseString: String!
        switch peripheral.state {
        case .unknown:
            caseString = "unknown"
        case .resetting:
            caseString = "resetting"
        case .unsupported:
            caseString = "unsupported"
        case .unauthorized:
            caseString = "unauthorized"
        case .poweredOff:
            caseString = "poweredOff"
        case .poweredOn:
            caseString = "poweredOn"
        }
        log("peripheralManagerDidUpdateState \(caseString!)")
        
        if peripheral.state == .poweredOn {
            log("isServiceInitialized \(isServiceInitialized)")
            if isServiceInitialized {
                log("peripheral.isAdvertising \(peripheral.isAdvertising)")
                if !peripheral.isAdvertising {
                    peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid]])
                }
            }
            else {
                peripheral.removeAllServices()
                peripheral.add(service)
            }
        }
        else if peripheral.state == .poweredOff {
            stopAdvertising()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        let message = "peripheralManager didAddService " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        log(message)
        guard error == nil else { return }
        isServiceInitialized = true
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [service.uuid]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        let message = "peripheralManagerDidStartAdvertising " + (error == nil ? "ok" :  ("error " + error!.localizedDescription))
        log(message)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        beginBackgroundTask()
        log("didReceiveWriteRequests \(requests.count)")
        for request in requests {
            // let characteristic = request.characteristic
            guard let value = request.value else {
                log("request.value is nil")
                return
            }
            log("received \(value.count) bytes:\(value.reduce("") { $0 + String(format: " %02x", $1) })")
            guard let intervalString = String(data: value, encoding: .utf8), let interval = TimeInterval(intervalString) else {
                log("couldn't parse interval")
                return
            }
            log("setting interval to \(interval)")
            self.interval = interval
            peripheral.respond(to: request, withResult: .success)
        }
        endBackgroundTask()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        beginBackgroundTask()
        log("peripheralManager didReceiveRead request")
        let start = Date()
        delegate?.readMotionData(interval: interval) { dataString in
            let intervalString = String(format: "%.6f", -start.timeIntervalSinceNow)
            log("received motion data in \(intervalString) secs")
            log("data: \(dataString)")
            request.value = dataString.data(using: .utf8, allowLossyConversion: false)
            peripheral.respond(to: request, withResult: .success)
        }
        endBackgroundTask()
    }
    
}

// MARK: background task

extension BluetoothManager {
    
    private func beginBackgroundTask() {
        log(#function)
        uiBackgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {
            [unowned self] in
            log("uiBackgroundTaskIdentifier \(self.uiBackgroundTaskIdentifier) expired")
            UIApplication.shared.endBackgroundTask(self.uiBackgroundTaskIdentifier)
            self.uiBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        })
        log("uiBackgroundTaskIdentifier \(uiBackgroundTaskIdentifier)")
    }
    
    private func endBackgroundTask() {
        log(#function)
        log("uiBackgroundTaskIdentifier \(uiBackgroundTaskIdentifier)")
        UIApplication.shared.endBackgroundTask(uiBackgroundTaskIdentifier)
        uiBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    }
    
}
