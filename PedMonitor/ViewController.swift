//
//  ViewController.swift
//  PedMonitor
//
//  Created by Jay Tucker on 12/19/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    private var bluetoothManager: BluetoothManager!
    
    private let pedometer = CMPedometer()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        log("viewDidLoad")

        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: .UIApplicationWillResignActive, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(appendMessage(_:)), name: NSNotification.Name(rawValue: newMessageNotificationName), object: nil)
        
        bluetoothManager = BluetoothManager()
        bluetoothManager.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        log("viewDidAppear")
        
        startPedometerUpdates()
        startPedometerEventUpdates()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func didBecomeActive() {
        log(#function)
    }
    
    @objc func willResignActive() {
        log(#function)
    }
    
    @objc func appendMessage(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let text = userInfo["text"] as? String else { return }
        DispatchQueue.main.async {
            let newText = self.textView.text + "\n" + text
            self.textView.text = newText
            self.textView.scrollRangeToVisible(NSRange(location: newText.count, length: 0))
        }
    }
    
    private func startPedometerUpdates() {
        guard CMPedometer.isDistanceAvailable() else { return }
        
        pedometer.startUpdates(from: Date()) { data, error in
            guard error == nil else {
                log("pedom error")
                return
            }
            guard let data = data else {
                log("pedom data is nil")
                return
            }
            log("pedom \(data.numberOfSteps) \(String(format: "%.3f",data.distance!.doubleValue))")
        }
    }
    
    private func startPedometerEventUpdates() {
        guard CMPedometer.isPedometerEventTrackingAvailable() else { return }
        
        pedometer.startEventUpdates { event, error in
            guard error == nil else {
                log("pedom event error")
                return
            }
            guard let event = event else {
                log("pedom event is nil")
                return
            }
            let typeString: String
            switch event.type {
            case .pause: typeString = "pause"
            case .resume: typeString = "resume"
            }
            log("pedom event \(typeString)")
        }
    }

}

extension ViewController: BluetoothManagerDelegate {
    
    func readMotionData(interval: TimeInterval, completion: @escaping (String) -> Void) {
        // completion("1234")
        let now = Date()
        pedometer.queryPedometerData(from: now - interval, to: now) { data, error in
            guard error == nil else {
                log("error")
                return
            }
            guard let data = data else {
                log("data is nil")
                return
            }
            completion("\(data.numberOfSteps)")
        }
    }
    
}


