//
//  ViewController.swift
//  PedMonitor
//
//  Created by Jay Tucker on 12/19/17.
//  Copyright © 2017 Imprivata. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        log("viewDidLoad")
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appendMessage(_:)), name: NSNotification.Name(rawValue: newMessageNotificationName), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        log("viewDidAppear")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

}

