//
//  ViewController.swift
//  M_L1
//
//  Created by Михаил Ковалевский on 25/09/2019.
//  Copyright © 2019 Mikhail Kavaleuski. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var source: String = ""
        
        do {
            source = try String(contentsOf: Bundle.main.url(forResource: "src", withExtension: "txt")!)
        } catch let err {
            fatalError(err.localizedDescription)
        }
        
        print(source)
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

