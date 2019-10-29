//
//  Analyzer.swift
//  M_L1-2
//
//  Created by Михаил Ковалевский on 02/10/2019.
//  Copyright © 2019 Mikhail Kavaleuski. All rights reserved.
//

import Foundation

// 6 + 3 Scala

struct CodeBlock {
    var code: String = ""
    var internalBlocks: [String:CodeBlock] = [:]
    var operands: [String:Int] = [:]
    var operators: [String:Int] = [:]
}

struct Metrics {
    var n1: Int = 0
    var n2: Int = 0
    
    var N1: Int = 0
    var N2: Int = 0
    
    var n: Int = 0
    var N: Int = 0
    var V: Int = 0
    
    var CL: Int = 0
    var cl: Float = 0
    var CLI: Int = 0
}

class CodeAnalyzer {
    private var code: String! = ""
    private var mainBlocks: CodeBlock! = CodeBlock(code: "", internalBlocks: [:], operands: [:], operators: [:])
    
    private var metrics: Metrics! = Metrics()
    private var buffMetricsName: String = ""
    private var buffMetrics: Metrics! = Metrics()
    
    private let commentPattern = #"(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/)|(//.*)"#
    private let functionPattern = #"((def)[^{}]*(\{))([^{}]*)(\})"#
    private let blankLinePattern = #"[\r\n] *[\r\n]"#
    private let unneededSpecesPattern = #" {2,}"#
    private let floatingSpecesPattern = #"\n *"#
    private let ternaryOperatorPattern = #"[^\n\r]+\?[^\n\r]*:[^\n\r]*"#
    private let complexOperatorPattern = #"(\w+ {0,1})(\(.*\))"#
    private let closedComplexOperatorPattern = #"(\w+ {0,1})(\([^()]*\))"#
    private let argPattern = #"[(,] *\w+:"#
    private let closedBracketsPattern = #"(\([^()]*\))"#
    private let stringPattern = #"\"[^"]*\""#
    
    private let objectBlockName = "object"
    private let functionBlockName = "def"
    
    private let closedBracketsKey = "(...)"
    private let closedBracketsKey1 = "[...]"
    
    private let simpleOperators: [String] = ["<<=",">>=","<<<",">>>","<<",">>","&&","||","==","!=","^=","|=","&=","%=","/=","*=","+=","-=",">=","<=","~","&","|","^","!","=",">","<","+","-","*","/","%",";",","]
    
    
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
        let parentheses: [[Character]] = [["{","}"],["(",")"],["[","]"]]
        var a: [Int] = Array(repeating: 0, count: parentheses.count)
        var i: String.Index = s.startIndex
        var ret: Bool = true
        
        while i<s.endIndex {
            switch s[i]{
            case parentheses[0][0]:
                a[0] = a[0] + 1;
            case parentheses[0][1]:
                a[0] = a[0] - 1;
            case parentheses[1][0]:
                a[1] = a[1] + 1;
            case parentheses[1][1]:
                a[1] = a[1] - 1;
            case parentheses[2][0]:
                a[2] = a[2] + 1;
            case parentheses[2][1]:
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
    
    private func removeFloatingSpaces(s: inout String){
        var buffCode: String = s.replacingOccurrences(of: floatingSpecesPattern, with: "\n", options: .regularExpression, range: nil)
        
        while buffCode != s {
            s = buffCode
            buffCode = s.replacingOccurrences(of: floatingSpecesPattern, with: "\n", options: .regularExpression, range: nil)
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
            mainBlocks.code = buffCode
        }
        
        b = findBlock(in: buffCode, startingWith: functionBlockName)
        while b != [:] {
            let k: String = b.first!.key
            mainBlocks.operands.updateValue(1, forKey: k)
            let v: Range<String.Index> = b.first!.value
            let cBlock: CodeBlock = CodeBlock(code: String(buffCode[v]), internalBlocks: [:], operands: [:], operators: [:])
            mainBlocks.internalBlocks.updateValue(cBlock, forKey: k)
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
    
    private func getSymbolCount(in s: String, symbol c: Character) -> Int {
        var count = 0
        var buffStr = s
        var pos = buffStr.firstIndex(of: c)
        while pos != nil {
            count = count + 1
            buffStr.remove(at: pos!)
            pos = buffStr.firstIndex(of: c)
        }
        return count
    }
    
    private func updateOperatorsRecursion(block: inout [String:CodeBlock]){
        block.forEach { (arg0) in
            let (key, value) = arg0
            var buffCode:String = value.code
            buffCode.removeFirst(key.count)
            
            var bracketCount = getSymbolCount(in: buffCode, symbol: "(")
            let bracketCount1 = getSymbolCount(in: buffCode, symbol: "[")
            
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
                bracketCount = bracketCount - opArray.count
                
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
            
            if bracketCount > 0 {
                block[key]!.operators.updateValue(bracketCount, forKey: closedBracketsKey)
            }
            
            if bracketCount1 > 0 {
                block[key]!.operators.updateValue(bracketCount1, forKey: closedBracketsKey1)
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
                if key1 != closedBracketsKey && key1 != closedBracketsKey1 {
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
                }
            })
            
            // Clears string
            let symbolsToRemove: [String] = ["(",")",".","{","}","val","var","else","_","?",":","match"]
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
                    if buffStr == "case" {
                        if block[key0]?.operators["if(...)"] == nil {
                            block[key0]!.operators.updateValue(1, forKey: "if(...)")
                        } else {
                            let lastVal: Int? = block[key0]!.operators["if(...)"]
                            block[key0]!.operators.updateValue(lastVal! + 1, forKey: "if(...)")
                        }
                    } else {
                        if block[key0]?.operands[buffStr] == nil {
                            block[key0]!.operands.updateValue(1, forKey: buffStr)
                        } else {
                            let lastVal: Int? = block[key0]!.operands[buffStr]
                            block[key0]!.operands.updateValue(lastVal! + 1, forKey: buffStr)
                        }
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
    
    private func countOverallMetrics(block: inout [String:CodeBlock]){
        block.forEach { (arg0) in
            let (key, value) = arg0
            
            value.operands.forEach({ (arg1) in
                let (_, value1) = arg1
                metrics.N2 = metrics.N2 + value1
            })
            metrics.n2 = metrics.n2 + value.operands.count
            
            value.operators.forEach({ (arg1) in
                let (_, value1) = arg1
                metrics.N1 = metrics.N1 + value1
            })
            metrics.n1 = metrics.n1 + value.operators.count
            
            if block[key]!.internalBlocks.count != 0 {
                countOverallMetrics(block: &block[key]!.internalBlocks)
            }
        }
    }
    
    private func updateMetricsValues(){
        countOverallMetrics(block: &mainBlocks.internalBlocks)
        metrics.n = metrics.n1 + metrics.n2
        metrics.N = metrics.N1 + metrics.N2
//        metrics.CL = 101
//        metrics.cl = 102
//        metrics.CLI = 103
        if metrics.n > 0 {
            metrics.V = metrics.N*Int(log2(Double(metrics.n)))
        }
    }
    
    func updateMetrics(){
        if code != "" {
            updateObjectBlock()
            updateInternalBlocksRecursion(block: &mainBlocks.internalBlocks)
            updateOperatorsRecursion(block: &mainBlocks.internalBlocks)
            updateOperandsRecursion(block: &mainBlocks.internalBlocks) // CALL AFTER OPERATORS SEARCH !
            updateMetricsValues()
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
        outputMetricsRecursion(block: &mainBlocks.internalBlocks)
        print(metrics!)
    }
    
    func outputCode(){
        print("Code:")
        print(code!)
    }
    
    private func getBlockNamesRecursion(block: inout [String:CodeBlock], arr: inout [String]){
        block.forEach { (arg0) in
            let (key, _) = arg0
            arr.append(key)
            if block[key]!.internalBlocks.count != 0 {
                getBlockNamesRecursion(block: &block[key]!.internalBlocks, arr: &arr)
            }
        }
    }
    
    func getBlockNames() -> [String]{
        var arr: [String] = []
        getBlockNamesRecursion(block: &mainBlocks.internalBlocks, arr: &arr)
        return arr
    }
    
    private func transformTernaryOperatorToStd(op: String) -> String {
        var str: String = op
        while str[str.startIndex] == " " {
            str.removeFirst()
        }
//        removeUnneededSpaces(s: &str)
        str.append("}")
        str.insert(contentsOf: "if ( ", at: str.startIndex)
        let p1: String.Index = str.firstIndex(of: "?")!
        str.remove(at: p1)
        str.insert(contentsOf: ") {\n", at: p1)
        let p2: String.Index = str.firstIndex(of: ":")!
        str.remove(at: p2)
        str.insert(contentsOf: "\n} else {\n", at: p2)
        
        str.append("\n")
        return str
    }
    
    private func transformMatchOperatorToStd(op: String) -> String {
        var str: String = op
        var alternatives: [String] = []
        var defaultAlternative: String = ""
        
        while str[str.startIndex] != "{"{
            str.removeFirst()
        }
        str.removeFirst()
        str.remove(at: str.lastIndex(of: "}")!)
        if str[str.startIndex] == "\n"{
            str.removeFirst()
        }
        
        let rng: Range<String.Index>? = str.range(of: "case _ =>")
        if rng != nil {
            defaultAlternative = String(str[str.index(after: str.lastIndex(of: "{")!)...str.index(before: str.lastIndex(of: "}")!)])
            str.removeSubrange(rng!.lowerBound...str.index(before: str.endIndex))
        }
        
        var p: String.Index? = str.firstIndex(of: "{")
        while p != nil {
            let p2: String.Index? = str.firstIndex(of: "}")
            alternatives.append(String(str[p!...str.index(before: p2!)]))
            str.removeSubrange(p!...p2!)
            p = str.firstIndex(of: "{")
        }
        
        str = ""
        
        if alternatives.count > 0 {
            alternatives.forEach { (alt) in
                str.append("if ( _ ) ")
                str.append(alt)
            }
            
            str.append(defaultAlternative)
            
            for _ in 0...alternatives.count-1{
                str.append("}\n")
            }
            
            str.removeLast()
        }
        removeBlankLines(s: &str)
        removeFloatingSpaces(s: &str)
        str.insert("\n", at: str.startIndex)
//        print(op)
//        print(alternatives)
//        print(defaultAlternative)
//        print(str)
        return str
    }
    
    private func getMaxNesting(str: String) -> Int {
        var buffNesting: Int = -1
        var buffMaxNesting: Int = 0
        var p: String.Index = str.startIndex
        while p < str.endIndex {
            if str[p] == "{" {
                buffNesting = buffNesting + 1
                if buffNesting > buffMaxNesting {
                    buffMaxNesting = buffNesting
                }
            } else
                if str[p] == "}" {
                    buffNesting = buffNesting - 1
                }
            p = str.index(after: p)
        }
//        print(buffMaxNesting)
        return buffMaxNesting
    }
    
    
    private func getJilbMetricsFromBlock(str: String, mt: inout Metrics){
        var newStr: String = str
        var rng:Range<String.Index>? = newStr.range(of: ternaryOperatorPattern, options: .regularExpression, range: nil, locale: nil)
        while rng != nil {
            let first: String.Index = rng!.lowerBound
            let newOperator: String = transformTernaryOperatorToStd(op: String(newStr[first...rng!.upperBound]))
            newStr.removeSubrange(first...rng!.upperBound)
            newStr.insert(contentsOf: newOperator, at: first)
            rng = newStr.range(of: ternaryOperatorPattern, options: .regularExpression, range: nil, locale: nil)
        }
        
        
        var blockDictionary:[String : Range<String.Index>] = findBlock(in: newStr, startingWith: "match")
        while blockDictionary != [:] {
            let k: String = blockDictionary.keys.first!
            rng = blockDictionary[k]
            
            let newOperator: String = transformMatchOperatorToStd(op: String(newStr[rng!.lowerBound...rng!.upperBound]))
            newStr.removeSubrange(rng!)
            newStr.insert(contentsOf: newOperator, at: rng!.lowerBound)
            
            blockDictionary = findBlock(in: newStr, startingWith: "match")
        }
        
        newStr = newStr.replacingOccurrences(of: "if(", with: "if (")
        newStr = newStr.replacingOccurrences(of: "while(", with: "if (")
        newStr = newStr.replacingOccurrences(of: "for(", with: "if (")
        newStr = newStr.replacingOccurrences(of: "while (", with: "if (")
        newStr = newStr.replacingOccurrences(of: "for (", with: "if (")
        newStr = newStr.replacingOccurrences(of: "} else {", with: "")
        
        newStr.remove(at: newStr.lastIndex(of: "}")!)
        
        while newStr[newStr.startIndex] != "{"{
            newStr.removeFirst()
        }
        newStr.removeFirst()
        
        mt.CL = newStr.components(separatedBy: "if (").count - 1
        mt.cl = Float(mt.CL)/Float(mt.N1)
        
        blockDictionary = findBlock(in: newStr, startingWith: "if (")
        while blockDictionary != [:] {
            let k: String = blockDictionary.keys.first!
            rng = blockDictionary[k]
            
            let buffNesting: Int = getMaxNesting(str: String(newStr[rng!]))
//            print(blockDictionary)
//            print("Nesting: ",buffNesting)
            if buffNesting > mt.CLI {
                mt.CLI = buffNesting
            }
            newStr.removeSubrange(rng!)

            blockDictionary = findBlock(in: newStr, startingWith: "if (")
        }
        
        
//        print(newStr)
    }
    
    private func getBlockMetrics(block: inout [String:CodeBlock], name: inout String?, mt: inout Metrics) {
        block.forEach { (arg0) in
            let (key, value) = arg0
            if name != nil {
                if key == name {
                    value.operands.forEach({ (arg1) in
                        let (_, value1) = arg1
                        mt.N2 = mt.N2 + value1
                    })
                    mt.n2 = mt.n2 + value.operands.count
                    
                    value.operators.forEach({ (arg1) in
                        let (_, value1) = arg1
                        mt.N1 = mt.N1 + value1
                    })
                    mt.n1 = mt.n1 + value.operators.count
                    
                    mt.n = mt.n1 + mt.n2
                    mt.N = mt.N1 + mt.N2
                    if mt.n > 0 {
                        mt.V = mt.N*Int(log2(Double(mt.n)))
                    }
                    
                    getJilbMetricsFromBlock(str: value.code, mt: &mt)
                    
                    name = nil
                }
                
                if name != nil && block[key]!.internalBlocks.count != 0 {
                    getBlockMetrics(block: &block[key]!.internalBlocks, name: &name, mt: &mt)
                }
            }
        }
    }
    
    func getMetricsOfBlock(name: String, t: String) -> Float {
        let m: Float
        if name == "Overall" {
            m = getOverallMetrics(t: t)
        } else {
            
            if name != buffMetricsName {
                var pName: String? = name
                buffMetrics = Metrics()
                getBlockMetrics(block: &mainBlocks.internalBlocks, name: &pName, mt: &buffMetrics)
                buffMetricsName = name
            }
            switch t {
            case "n1":
                m = Float(buffMetrics.n1)
            case "n2":
                m = Float(buffMetrics.n2)
            case "N1":
                m = Float(buffMetrics.N1)
            case "N2":
                m = Float(buffMetrics.N2)
            case "n":
                m = Float(buffMetrics.n)
            case "N":
                m = Float(buffMetrics.N)
            case "V":
                m = Float(buffMetrics.V)
            case "CL":
                m = Float(buffMetrics.CL)
            case "cl":
                m = buffMetrics.cl
            case "CLI":
                m = Float(buffMetrics.CLI)
            default:
                m = 0
            }
        }
        return m
    }
    
    private func getOverallMetrics(t: String) -> Float{
        let m: Float
        switch t {
        case "n1":
            m = Float(buffMetrics.n1)
        case "n2":
            m = Float(buffMetrics.n2)
        case "N1":
            m = Float(buffMetrics.N1)
        case "N2":
            m = Float(buffMetrics.N2)
        case "n":
            m = Float(buffMetrics.n)
        case "N":
            m = Float(buffMetrics.N)
        case "V":
            m = Float(buffMetrics.V)
        case "CL":
            m = Float(buffMetrics.CL)
        case "cl":
            m = buffMetrics.cl
        case "CLI":
            m = Float(buffMetrics.CLI)
        default:
            m = 0
        }
        return m
    }
    
    private func getOperatorsDictionariesRecursion(block: inout [String:CodeBlock], dict: inout [String:[String:Int]]) {
        block.forEach { (arg0) in
            let (key, value) = arg0
            dict.updateValue(value.operators, forKey: key)
            if block[key]!.internalBlocks.count != 0 {
                getOperatorsDictionariesRecursion(block: &block[key]!.internalBlocks, dict: &dict)
            }
            
        }
    }
    
    func getOperatorsDictionaries() -> [String:[String:Int]] {
        var dict:[String:[String:Int]] = [:]
        getOperatorsDictionariesRecursion(block: &mainBlocks.internalBlocks, dict: &dict)
        return dict
    }
    
    
    private func getOperandsDictionariesRecursion(block: inout [String:CodeBlock], dict: inout [String:[String:Int]]) {
        block.forEach { (arg0) in
            let (key, value) = arg0
            dict.updateValue(value.operands, forKey: key)
            if block[key]!.internalBlocks.count != 0 {
                getOperandsDictionariesRecursion(block: &block[key]!.internalBlocks, dict: &dict)
            }
            
        }
    }
    
    func getOperandsDictionaries() -> [String:[String:Int]] {
        var dict:[String:[String:Int]] = [:]
        getOperandsDictionariesRecursion(block: &mainBlocks.internalBlocks, dict: &dict)
        return dict
    }
    
    
}

//
//func main() -> Int{
//
//    var source: String = ""
//
//    do {
//        source = try String(contentsOf: Bundle.main.url(forResource: "src", withExtension: "scala")!)
//        print("Succesfuly loaded source code!")
//    } catch let err {
//        fatalError(err.localizedDescription)
//    }
//
//    let analyzer: CodeAnalyzer = CodeAnalyzer(s: source)
//    //    analyzer.outputCode()
//    analyzer.updateMetrics()
//    analyzer.outputMetrics()
//
//    return 0
//}
//
//let result = main()
//print()
//print("Main func return code:", result)



