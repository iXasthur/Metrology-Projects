//
//  main.swift
//  M_L1_TERMINAL
//
//  Created by Михаил Ковалевский on 27/09/2019.
//  Copyright © 2019 Mikhail Kavaleuski. All rights reserved.
//

import Foundation

// 6 + 3 Scala

struct MetricsElement {
    var name: String = ""
    var count: Int = 0
}

struct CodeBlock {
    var code: String = ""
    var operands: [String:Int] = [:]
    var operators: [String:Int] = [:]
}

class CodeAnalyzer {
    private var code: String! = ""
    private var metrics: [String:CodeBlock]! = [:]
    
    private let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
    private let functionPattern = #"((def)[^{}]*(\{))([^{}]*)(\})"#
    private let blankLinePattern = #"[\r\n] *[\r\n]"#
    private let unneededSpecesPattern = #" {2,}"#
    
    private let objectBlockName = "object"
    private let functionBlockName = "def"
    
    init(s: String) {
        code = s
        removeComments()
        removeBlankLines()
//        removeUnnededSpaces()
    }
    
    private func removeComments(){
        code = code.replacingOccurrences(of: commentPattern, with: "", options: .regularExpression, range: nil)
    }
    
    private func removeBlankLines(){
        var buffCode: String = code.replacingOccurrences(of: blankLinePattern, with: "\n", options: .regularExpression, range: nil)
        
        while buffCode != code {
            code = buffCode
            buffCode = code.replacingOccurrences(of: blankLinePattern, with: "\n", options: .regularExpression, range: nil)
        }
    }
    
    private func removeUnnededSpaces(){
        var buffCode: String = code.replacingOccurrences(of: unneededSpecesPattern, with: "", options: .regularExpression, range: nil)
        
        while buffCode != code {
            code = buffCode
            buffCode = code.replacingOccurrences(of: unneededSpecesPattern, with: "", options: .regularExpression, range: nil)
        }
    }
    
    private func findBlock(in str: String,startingWith s: String) -> [String:Range<String.Index>]{
        guard let r: Range<String.Index> = str.range(of: s) else {
            print(("-> No block found starting with \"\(s)\"!"))
            return [:]
        }
        print("Found block starting with \"\(s)\"!")
        
        let blockStartIndex: String.Index = r.lowerBound
        var bracketsToSkip: Int = -1
        var i: String.Index = blockStartIndex
        var name: String = ""
        while str[i] != "{" {
            name = name + String(str[i])
            i = str.index(i, offsetBy: 1)
        }
        i = str.index(i, offsetBy: -1)
        
        while str[i] != "}" || bracketsToSkip >= 0 {
            i = str.index(i, offsetBy: 1)
            switch str[i] {
            case "{":
                bracketsToSkip = bracketsToSkip + 1
            case "}":
                bracketsToSkip = bracketsToSkip - 1
            default:
                break
            }
        }
        
        i = str.index(i, offsetBy: 1)
        let blockRange: Range<String.Index> = blockStartIndex..<i
        return [name:blockRange]
    }
    
    func updateMetrics(){
        var buffCode: String = code
        var b:[String:Range<String.Index>] = findBlock(in: buffCode, startingWith: objectBlockName)
        if b != [:] {
            let k: String = b.first!.key
            let v: Range<String.Index> = b.first!.value
            metrics.updateValue(CodeBlock(code: String(buffCode[v]), operands: [:], operators: [:]), forKey: k)
        }
        
        b = findBlock(in: buffCode, startingWith: functionBlockName)
        while b != [:] {
            let k: String = b.first!.key
            let v: Range<String.Index> = b.first!.value
            metrics.updateValue(CodeBlock(code: String(buffCode[v]), operands: [:], operators: [:]), forKey: k)
            buffCode.removeSubrange(v)
            b = findBlock(in: buffCode, startingWith: functionBlockName)
        }
        
        
    }
    
    func outputMetrics(){
        print("Metrics:")
        print()
        
        metrics.forEach { (arg0) in
            let (key, value) = arg0
            if key.range(of: objectBlockName) == nil {
                print("Block: \(key)")
                print("Code: \(value.code)")
                print()
            } else {
                print("Skipped object block")
                print()
            }
        }
    }
    
    func outputCode(){
        print("Code:")
        print(code!)
    }
}

func main() -> Int{
    
    var source: String = ""
    
    do {
        source = try String(contentsOf: Bundle.main.url(forResource: "src", withExtension: "scala")!)
        print("Succesfuly loaded source code!")
    } catch let err {
        fatalError(err.localizedDescription)
    }
    
    let analyzer: CodeAnalyzer = CodeAnalyzer(s: source)
//    analyzer.outputCode()
    analyzer.updateMetrics()
    analyzer.outputMetrics()
    
    return 0
}

let result = main()
print()
print("Main func return code:", result)


