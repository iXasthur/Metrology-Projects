//
//  ViewController.swift
//  M_L1-2
//
//  Created by Михаил Ковалевский on 25/09/2019.
//  Copyright © 2019 Mikhail Kavaleuski. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    @IBOutlet weak var outlineView: NSOutlineView!
    var blockNames: [String] = ["Overall"]
    let operandsFieldName:String = "Operands(f2)"
    let operatorsFieldName:String = "Operators(f1)"
    let jilbMetricsNames:[String] = ["CL","cl","CLI"]
    let emptyMetricIdentifier:String = "%EMPTY%"
    var metricsNames: [String] = ["n1","n2","N1","N2","n","N","V"]
    var operatorsDictiotary: [String:[String:Int]] = [:]
    var operatorsDictionarySortedKeysDictionary: [String:[String]] = [:]
    var operandsDictiotary: [String:[String:Int]] = [:]
    var operandsDictionarySortedKeysDictionary: [String:[String]] = [:]
    var analyzer: CodeAnalyzer!
    
    private func clearItemIdentifier(s: String) -> String? {
        let str: String?
        let r: String.Index? = s.lastIndex(of: "_")
        if r != nil {
            let rightBorder: String.Index = s.index(s.endIndex, offsetBy: -1)
            let leftBorder: String.Index = s.index(r!, offsetBy: 1)
            str = String(s[leftBorder...rightBorder])
        } else {
            str = nil
        }
        return str
    }
    
    override func viewDidLoad() {
//        metricsNames.append(emptyMetricIdentifier)
        metricsNames.append(operatorsFieldName)
        metricsNames.append(operandsFieldName)
        
        metricsNames.append(emptyMetricIdentifier)
        jilbMetricsNames.forEach { (m) in
            metricsNames.append(m)
        }
        super.viewDidLoad()
        
        var source: String = ""
        
        do {
            source = try String(contentsOf: Bundle.main.url(forResource: "src", withExtension: "scala")!)
        } catch let err {
            fatalError(err.localizedDescription)
        }
        
        analyzer = CodeAnalyzer(s: source)
        analyzer.updateMetrics()
//        analyzer.outputMetrics()
        analyzer.getBlockNames().forEach { (s) in
            blockNames.append(s)
        }
        
        operatorsDictiotary = analyzer.getOperatorsDictionaries()
        operandsDictiotary = analyzer.getOperandsDictionaries()
        
        operandsDictiotary.forEach { (arg0) in
            let (key, value) = arg0
            var arr: [String] = []
            let vl = value.sorted(by: { (arg1, arg2) -> Bool in
                let (_, value1) = arg1
                let (_, value2) = arg2
                if value1 > value2 {
                    return true
                } else {
                    return false
                }
            })
            
            vl.forEach({ (arg1) in
                let (key1, _) = arg1
                arr.append(key1)
            })
            
            operandsDictionarySortedKeysDictionary.updateValue(arr, forKey: key)
        }
        
        operatorsDictiotary.forEach { (arg0) in
            let (key, value) = arg0
            var arr: [String] = []
            let vl = value.sorted(by: { (arg1, arg2) -> Bool in
                let (_, value1) = arg1
                let (_, value2) = arg2
                if value1 > value2 {
                    return true
                } else {
                    return false
                }
            })
            
            vl.forEach({ (arg1) in
                let (key1, _) = arg1
                arr.append(key1)
            })
            
            operatorsDictionarySortedKeysDictionary.updateValue(arr, forKey: key)
        }
        
        outlineView.dataSource = self
        outlineView.delegate = self
    }
    
    // You must give each row a unique identifier, referred to as `item` by the outline view
    //   * For top-level rows, we use the values in the `keys` array
    //   * For the hobbies sub-rows, we label them as ("hobbies", 0), ("hobbies", 1), ...
    //     The integer is the index in the hobbies array
    //
    // item == nil means it's the "root" row of the outline view, which is not visible
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        let itemStr = item as? String
        if item == nil {
            return blockNames[index]
        } else {
            if itemStr != nil {
                if blockNames.contains(itemStr!) {
                    if itemStr == "Overall" {
                        if  (metricsNames[index] == operandsFieldName || metricsNames[index] == operatorsFieldName) {
                            return String(itemStr! + "_" + metricsNames[index+2])
                        } else {
                            if index < metricsNames.firstIndex(of: emptyMetricIdentifier) ?? 0 {
                                return String(itemStr! + "_" + metricsNames[index])
                            } else {
                                return String(itemStr! + "_" + metricsNames[index+2])
                            }
                        }
                    } else {
                        return String(itemStr! + "_" + metricsNames[index])
                    }
                } else {
                    var buffStr: String = itemStr!
                    var r: Range<String.Index>? = buffStr.range(of: "_"+operatorsFieldName)
                    if r != nil {
                        buffStr.removeSubrange(r!)
                        if blockNames.contains(buffStr){
                            let retStr: String? = operatorsDictionarySortedKeysDictionary[buffStr]?[index]
                            if retStr != nil {
                                return String(itemStr! + "_" + retStr!)
                            } else {
                                return 0
                            }
                        } else {
                            return 0
                        }
                    } else {
                        r = buffStr.range(of: "_"+operandsFieldName)
                        if r != nil {
                            buffStr.removeSubrange(r!)
                            if blockNames.contains(buffStr){
                                let retStr: String? = operandsDictionarySortedKeysDictionary[buffStr]?[index]
                                if retStr != nil {
                                    return String(itemStr! + "_" + retStr!)
                                } else {
                                    return 0
                                }
                            } else {
                                return 0
                            }
                        } else {
                            return 0
                        }
                    }
                }
            } else {
                return 0
            }
            
            
        }
    }
    
    // Tell how many children each row has:
    //    * The root row has 5 children: name, age, birthPlace, birthDate, hobbies
    //    * The hobbies row has how ever many hobbies there are
    //    * The other rows have no children
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return blockNames.count
        } else {
            guard var itemStr = item as? String else {
                return 0
            }
            if blockNames.contains(itemStr){
                if itemStr == "Overall" {
                    return metricsNames.count - 2
                } else {
                    return metricsNames.count
                }
            } else {
                var r: Range<String.Index>? = itemStr.range(of: "_"+operatorsFieldName)
                if r != nil {
                    itemStr.removeSubrange(r!)
                    if blockNames.contains(itemStr){
                        return operatorsDictiotary[itemStr]?.count ?? 0
                    } else {
                        return 0
                    }
                } else {
                    r = itemStr.range(of: "_"+operandsFieldName)
                    if r != nil {
                        itemStr.removeSubrange(r!)
                        if blockNames.contains(itemStr){
                            return operandsDictiotary[itemStr]?.count ?? 0
                        } else {
                            return 0
                        }
                    } else {
                        return 0
                    }
                }
            }
        }
    }
    
    // Tell whether the row is expandable. The only expandable row is the Hobbies row
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let itemStr = item as? String else {
            return false
        }
        
        if blockNames.contains(itemStr) {
            return true
        } else {
            let r = clearItemIdentifier(s: itemStr)
            if r == operandsFieldName || r == operatorsFieldName {
                return true
            } else {
                return false
            }
        }
    }
    
    // Set the text for each row
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let columnIdentifier = tableColumn?.identifier.rawValue else {
            return nil
        }
        var text = ""
        
        // Recall that `item` is the row identiffier
        switch (columnIdentifier, item) {
        case ("keyColumn", let item as String):
            let nText = clearItemIdentifier(s: item)
            if nText != nil {
                text = nText!
            } else {
                var newText: String = item
                var leftBorder: String.Index? = newText.firstIndex(of: "(")
                var rightBorder: String.Index? = newText.lastIndex(of: ")")
                if leftBorder != nil && rightBorder != nil && newText.distance(from: leftBorder!, to: rightBorder!) != 1  {
                    leftBorder = newText.index(after: leftBorder!)
                    rightBorder = newText.index(before: rightBorder!)
                    newText.removeSubrange(leftBorder!...rightBorder!)
                }
                
                text = newText
                let prefix = "def "
                if text.hasPrefix(prefix) {
                    text.removeFirst(prefix.count)
                }
            }
            
            if text == emptyMetricIdentifier {
                text = ""
            }
            
//            text = item
        case ("keyColumn", _):
            // Remember that we identified the hobby sub-rows differently
            break
        case ("valueColumn", let item as String):
            let ident: String? = clearItemIdentifier(s: item)
            if ident != nil {
                let blockedStrings: [String] = [operatorsFieldName, operandsFieldName, emptyMetricIdentifier]
                var check: Bool = true
                blockedStrings.forEach { (s) in
                    if item.range(of: s) != nil {
                        check = false
                    }
                }
                if check && metricsNames.contains(ident!) {
                    blockNames.forEach { (s) in
                        if item.hasPrefix(s){
                            let value: Float = analyzer.getMetricsOfBlock(name: s, t: ident!)
                            let decimal = value.truncatingRemainder(dividingBy: 1)
                            if decimal > 0 {
                                text = String(value)
                            } else {
                                if value > 0 {
                                    text = String(Int(value))
                                } else {
                                    text = "0"
                                }
                            }
                            
                        }
                    }
                } else
                    if !check {
                        var itemStr = item
                        let lastIndex: String.Index = item.index(before: item.endIndex)
                        var value: Int? = nil
                        
                        var r: Range<String.Index>? = item.range(of: "_"+operatorsFieldName)
                        if r != nil {
                            let firstIndex: String.Index = r!.lowerBound
                            itemStr.removeSubrange(firstIndex...lastIndex)
                            value = operatorsDictiotary[itemStr]?[ident!]
                        } else {
                            r = item.range(of: "_"+operandsFieldName)
                            if r != nil {
                                let firstIndex: String.Index = r!.lowerBound
                                itemStr.removeSubrange(firstIndex...lastIndex)
                                value = operandsDictiotary[itemStr]?[ident!]
                            }
                        }
                        
                        if value != nil {
                            text = String(value!)
                        }
                }
            }
        default:
            break
        }
        
        let cellIdentifier = NSUserInterfaceItemIdentifier("outlineViewCell")
        let cell = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as! NSTableCellView
        cell.textField!.stringValue = text
        
        return cell
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

