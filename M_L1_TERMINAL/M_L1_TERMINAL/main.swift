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
    private var metrics: CodeBlock! = CodeBlock(code: "", internalBlocks: [:], operands: [:], operators: [:])
    
    private let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
    private let functionPattern = #"((def)[^{}]*(\{))([^{}]*)(\})"#
    private let blankLinePattern = #"[\r\n] *[\r\n]"#
    private let unneededSpecesPattern = #" {2,}"#
    private let complexOperatorPattern = #"(\w+ {0,1})(\(.*\))"#
    private let closedComplexOperatorPattern = #"(\w+ {0,1})(\([^()]*\))"#
    private let argPattern = #"[(,] *\w+:"#
    private let closedBracketsPattern = #"(\([^()]*\))"#
    private let stringPattern = #"\"[^"]*\""#
    
    private let objectBlockName = "object"
    private let functionBlockName = "def"
    
    private let simpleOperators: [String] = ["<<=",">>=","<<<",">>>","<<",">>","&&","||","==","!=","^=","|=","&=","%=","/=","*=","+=","-=",">=","<=","~","&","|","^","!","=",">","<","+","-","*","/","%",";"]
    
    
    init(s: String) {
        code = s
        removeComments(s: &code)
        removeBlankLines(s: &code)
        removeUnneededSpaces(s: &code)
        
        if !checkCodeForParentheses(s: code) {
            code = ""
            print("-> There are some errors in the source code. Resetting code to blank string")
        }
    }
    
    private func checkCodeForParentheses(s: String) -> Bool {
        let parenthesses: [[Character]] = [["{","}"],["(",")"],["[","]"]]
        var a: [Int] = Array(repeating: 0, count: parenthesses.count)
        var i: String.Index = s.startIndex
        var ret: Bool = true
        
        while i<s.endIndex {
            switch s[i]{
            case parenthesses[0][0]:
                a[0] = a[0] + 1;
            case parenthesses[0][1]:
                a[0] = a[0] - 1;
            case parenthesses[1][0]:
                a[1] = a[1] + 1;
            case parenthesses[1][1]:
                a[1] = a[1] - 1;
            case parenthesses[2][0]:
                a[2] = a[2] + 1;
            case parenthesses[2][1]:
                a[2] = a[2] - 1;
            default:
                break
            }
            i = s.index(i, offsetBy: 1)
        }
        
        a.forEach { (z) in
            if z != 0 {
                ret = false
            }
        }
        
        return ret
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
            
            // Finds simple operators
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
            
            // Finds complex operators
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
            
            if block[key]!.internalBlocks.count != 0 {
                updateOperatorsRecursion(block: &block[key]!.internalBlocks)
            }
        }
    }
    
    private func updateOperandsRecursion(block: inout [String:CodeBlock]){
        block.forEach { (arg0) in
            let (key0, value0) = arg0
            var buffCode:String = value0.code
            buffCode.removeFirst(key0.count)
            
            // Removes simple operators
            simpleOperators.forEach({ (s) in
                buffCode = buffCode.replacingOccurrences(of: s, with: " ")
            })
            
            // Finds string operands
            var rng: Range<String.Index>? = buffCode.range(of: stringPattern, options: .regularExpression, range: nil, locale: nil)
            while rng != nil {
                let constStr: String = String(buffCode[rng!])
                if block[key0]!.operands[constStr] == nil {
                    block[key0]!.operands.updateValue(1, forKey: constStr)
                } else {
                    let lastVal: Int? = block[key0]!.operands[constStr]
                    block[key0]!.operands.updateValue(lastVal! + 1, forKey: constStr)
                }
                buffCode.removeSubrange(rng!)
                rng = buffCode.range(of: stringPattern, options: .regularExpression, range: nil, locale: nil)
            }
            
            // Removes complex operators
            value0.operators.forEach({ (arg1) in
                let (key1, _) = arg1
                
                var pos: String.Index? = key1.firstIndex(of: "(")
                if pos != nil {
                    var strToReplace: String = ""
                    pos = key1.index(pos!, offsetBy: -1)
                    strToReplace = String(key1[key1.startIndex...pos!])
                    strToReplace = #"[^\w]"# + strToReplace + #"[^\w]"#
                    
                    var r = buffCode.range(of: strToReplace, options: .regularExpression, range: nil, locale: nil)
                    while r != nil {
                        let leftBound = buffCode.index(r!.lowerBound, offsetBy: 1)
                        let rightBound = buffCode.index(r!.upperBound, offsetBy: -1)
                        buffCode.removeSubrange(leftBound...rightBound)
                        r = buffCode.range(of: strToReplace, options: .regularExpression, range: nil, locale: nil)
                    }
                }
            })
            
            // Clears string
            let symbolsToRemove: [String] = ["(",")",",",".","{","}","val","var"]
            symbolsToRemove.forEach({ (sym) in
                buffCode = buffCode.replacingOccurrences(of: sym, with: " ")
            })
            
            var saveCode: String = ""
            while saveCode != buffCode {
                saveCode = buffCode
                buffCode = buffCode.replacingOccurrences(of: #"\s"#, with: " ", options: .regularExpression, range: nil)
                buffCode = buffCode.replacingOccurrences(of: "  ", with: " ")
            }
            
            // Finds operands
            var buffStr: String = ""
            var i: String.Index = buffCode.startIndex
            while (i<buffCode.endIndex) && buffCode[i] == " " {
                i = buffCode.index(i, offsetBy: 1)
            }
            while i<buffCode.endIndex {
                if buffCode[i] == " " {
                    if block[key0]?.operands[buffStr] == nil {
                        block[key0]!.operands.updateValue(1, forKey: buffStr)
                    } else {
                        let lastVal: Int? = block[key0]!.operands[buffStr]
                        block[key0]!.operands.updateValue(lastVal! + 1, forKey: buffStr)
                    }
                    buffStr = ""
                } else {
                    buffStr = buffStr + String(buffCode[i])
                }
                
                i = buffCode.index(i, offsetBy: 1)
            }
            
            if block[key0]!.internalBlocks.count != 0 {
                updateOperandsRecursion(block: &block[key0]!.internalBlocks)
            }
            
        }
    }
    
    func updateMetrics(){
        if code != "" {
            updateObjectBlock()
            updateInternalBlocksRecursion(block: &metrics.internalBlocks)
            updateOperatorsRecursion(block: &metrics.internalBlocks)
            updateOperandsRecursion(block: &metrics.internalBlocks)
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


