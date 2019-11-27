//
//  ViewController.swift
//  M_L3
//
//  Created by Михаил Ковалевский on 27.11.2019.
//  Copyright © 2019 Михаил Ковалевский. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var outputLabelSpen: NSTextField!
    @IBOutlet weak var outputLabelChepinFull: NSTextField!
    @IBOutlet weak var outputLabelChepinIO: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var source: String = ""
        do {
            source = try String(contentsOf: Bundle.main.url(forResource: "src", withExtension: "scala")!)
            print("-> Succesfuly loaded source code!")
        } catch let err {
            fatalError(err.localizedDescription)
        }

        let Analyzer: CodeAnalyzer = CodeAnalyzer(s: source)
//        print("---------------------------------")
//        Analyzer.outputVariables()
//        Analyzer.outputMetrics()
//        Analyzer.outputCode()
        outputLabelSpen.stringValue = Analyzer.getSpenOutputStr()
        outputLabelChepinFull.stringValue = Analyzer.getChepinFullStr()
        outputLabelChepinIO.stringValue = Analyzer.getChepinIOStr()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

