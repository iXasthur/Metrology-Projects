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
    var internalBlocks: [String:CodeBlock] = [:]
    var operands: [String:Int] = [:]
    var operators: [String:Int] = [:]
}

class CodeAnalyzer {
    private var code: String! = ""
//    private var metrics: [String:CodeBlock]! = [:]
    private var metrics: CodeBlock! = CodeBlock(code: "", internalBlocks: [:], operands: [:], operators: [:])
    
    private let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
    private let functionPattern = #"((def)[^{}]*(\{))([^{}]*)(\})"#
    private let blankLinePattern = #"[\r\n] *[\r\n]"#
    private let unneededSpecesPattern = #" {2,}"#
    private let complexOperatorPattern = #"(\w+ {0,1})(\(.*\))"#
    private let closedComplexOperatorPattern = #"(\w+ {0,1})(\([^()]*\))"#
//    private let bracketsPattern = #"(\(.*\))"#
    private let closedBracketsPattern = #"(\([^()]*\))"#
    
    private let objectBlockName = "object"
    private let functionBlockName = "def"
    
    private let simpleOperators: [String] = ["<<=",">>=","<<<",">>>","<<",">>","&&","||","==","!=","^=","|=","&=","%=","/=","*=","+=","-=",">=","<=","~","&","|","^","!","=",">","<","+","-","*","/","%",";"]
    private let complexOperators: [String] = []
    
    
    init(s: String) {
        code = s
        removeComments(s: &code)
        removeBlankLines(s: &code)
//        removeUnneededSpaces(s: &code)
        
        if !checkCodeForParentheses(s: code) {
            code = ""
            print("-> There are some errors in the source code. Resetting code to blank string")
        }
    }
    
    private func checkCodeForParentheses(s: String) -> Bool {
        var a: Int = 0
        var i: String.Index = s.startIndex
        while i<s.endIndex {
            switch s[i]{
            case "{":
                a = a + 1;
            case "}":
                a = a - 1;
            default:
                break
            }
            i = s.index(i, offsetBy: 1)
        }
        
        if a == 0 {
            return true
        } else {
            return false
        }
    }
    
    private func removeComments(s: inout String){
        s = s.replacingOccurrences(of: commentPattern, with: "", options: .regularExpression, range: nil)
    }
    
    private func removeBlankLines(s: inout String){
        var buffCode: String = s.replacingOccurrences(of: blankLinePattern, with: "\n", options: .regularExpression, range: nil)
        
        while buffCode != s {
            s = buffCode
            buffCode = s.replacingOccurrences(of: blankLinePattern, with: "\n", options: .regularExpression, range: nil)
        }
    }
    
    private func removeUnneededSpaces(s: inout String){
        var buffCode: String = s.replacingOccurrences(of: unneededSpecesPattern, with: "", options: .regularExpression, range: nil)
        
        while buffCode != s {
            s = buffCode
            buffCode = s.replacingOccurrences(of: unneededSpecesPattern, with: "", options: .regularExpression, range: nil)
        }
    }
    
    private func findBlock(in str: String,startingWith s: String) -> [String:Range<String.Index>]{
        guard let r: Range<String.Index> = str.range(of: s) else {
//            print(("-> No block found starting with \"\(s)\"!"))
            return [:]
        }
//        print("Found block starting with \"\(s)\"!")
        
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
    
    private func updateInternalBlocksRecursion(block: inout [String:CodeBlock]){
        block.forEach { (arg0) in
            let (key, value) = arg0
            var buffCode:String = value.code
            buffCode.removeFirst(functionBlockName.count)
            
            var b:[String:Range<String.Index>] = findBlock(in: buffCode, startingWith: functionBlockName)
            while b != [:] {
                let k: String = b.first!.key
                let v: Range<String.Index> = b.first!.value
                let cBlock: CodeBlock = CodeBlock(code: String(buffCode[v]), internalBlocks: [:], operands: [:], operators: [:])
                block[key]!.internalBlocks.updateValue(cBlock, forKey: k)
                buffCode.removeSubrange(v)
                b = findBlock(in: buffCode, startingWith: functionBlockName)
            }
            
            removeBlankLines(s: &buffCode)
//            removeUnneededSpaces(s: &buffCode)
            block[key]!.code = functionBlockName + buffCode
            
            
            if block[key]!.internalBlocks.count != 0 {
                updateInternalBlocksRecursion(block: &block[key]!.internalBlocks)
            }
        }
    }
    
    private func updateObjectBlock(){
        var buffCode: String = code
        var b:[String:Range<String.Index>] = findBlock(in: buffCode, startingWith: objectBlockName)
        if b != [:] {
            let v: Range<String.Index> = b.first!.value
            buffCode = String(buffCode[v])
            metrics.code = buffCode
        }
        
        b = findBlock(in: buffCode, startingWith: functionBlockName)
        while b != [:] {
            let k: String = b.first!.key
            let v: Range<String.Index> = b.first!.value
            let cBlock: CodeBlock = CodeBlock(code: String(buffCode[v]), internalBlocks: [:], operands: [:], operators: [:])
            metrics.internalBlocks.updateValue(cBlock, forKey: k)
            buffCode.removeSubrange(v)
            b = findBlock(in: buffCode, startingWith: functionBlockName)
        }
    }
    
    private func clearComplexOperator(s: String) -> String {
        var newStr: String = "ERROR"
        let r: String.Index? = s.firstIndex(of: "(")
        if r != nil {
            newStr = String(s[s.startIndex...r!])
            newStr = newStr + "...)"
        }
        return newStr.replacingOccurrences(of: " ", with: "")
    }
    
    private func findComplexOperators(s: inout String, arr: inout [String]){
        var r: Range<String.Index>? = s.range(of: closedComplexOperatorPattern, options: .regularExpression, range: nil, locale: nil)
        while r != nil {
            arr.append(clearComplexOperator(s: String(s[r!])))
            s.removeSubrange(r!)
            r = s.range(of: closedComplexOperatorPattern, options: .regularExpression, range: nil, locale: nil)
        }
        r = s.range(of: closedBracketsPattern, options: .regularExpression, range: nil, locale: nil)
        if r != nil {
            s.removeSubrange(r!)
            findComplexOperators(s: &s, arr: &arr)
        }
    }
    
    private func updateOperatorsRecursion(block: inout [String:CodeBlock]){
        block.forEach { (arg0) in
            let (key, value) = arg0
            var buffCode:String = value.code
            buffCode.removeFirst(key.count)
            
            simpleOperators.forEach({ (op) in
                var count: Int = 0
                var pos: Range<String.Index>? = buffCode.range(of: op)
                while pos != nil {
                    count = count + 1
                    buffCode.removeSubrange(pos!)
                    pos = buffCode.range(of: op)
                }
                
                if count > 0 {
                    block[key]?.operators.updateValue(count, forKey: op)
                }
            })
            
            var r:Range<String.Index>? = buffCode.range(of: complexOperatorPattern, options: .regularExpression, range: nil, locale: nil)
            while r != nil {
                var op: String = String(buffCode[r!])
                var opArray: [String] = []
                
                findComplexOperators(s: &op, arr: &opArray)
                
                opArray.forEach({ (s) in
                    if block[key]!.operators[s] == nil {
                        block[key]!.operators.updateValue(1, forKey: s)
                    } else {
                        let prevValue = block[key]!.operators[s]
                        block[key]!.operators.updateValue(prevValue! + 1, forKey: s)
                    }
                })
                buffCode.removeSubrange(r!)
                r = buffCode.range(of: complexOperatorPattern, options: .regularExpression, range: nil, locale: nil)
            }
            
//            print(buffCode)
            removeBlankLines(s: &buffCode)
//            block[key]!.code = buffCode
            
            if block[key]!.internalBlocks.count != 0 {
                updateOperatorsRecursion(block: &block[key]!.internalBlocks)
            }
        }
    }
    
    func updateMetrics(){
        if code != "" {
            updateObjectBlock()
            updateInternalBlocksRecursion(block: &metrics.internalBlocks)
            updateOperatorsRecursion(block: &metrics.internalBlocks)
        }
    }
    
    private func outputMetricsRecursion(block: inout [String:CodeBlock]){
        block.forEach { (arg0) in
            let (key, value) = arg0
            print("Block: \(key)")
            print("Code:")
            print("\(value.code)")
            print("Operands: \(value.operands)")
            print("Operators: \(value.operators)")
            print()
            
            if value.internalBlocks.count != 0 {
                outputMetricsRecursion(block: &block[key]!.internalBlocks)
            }
        }
    }
    
    func outputMetrics(){
        print("Metrics:")
        outputMetricsRecursion(block: &metrics.internalBlocks)
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


