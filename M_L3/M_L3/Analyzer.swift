//
//  Analyzer.swift
//  M_L1-2
//
//  Created by Михаил Ковалевский on 02/10/2019.
//  Copyright © 2019 Mikhail Kavaleuski. All rights reserved.
//

import Foundation

class CodeAnalyzer {
    private struct ScalaVariable {
        var initString: String = ""
        var name: String = ""
        var spen: Int = -1
        var wasModified: Bool = false
        var wasUsed: Bool = false
        var isControlVariable: Bool = false
        var isInputVariable: Bool = false
        var isOutputVariable: Bool = false
    }
    
    private enum Metric_Group {
        case P
        case M
        case C
        case T
    }
    
    private struct Metrics {
        
        static let a1: Double = 1
        static let a2: Double = 2
        static let a3: Double = 3
        static let a4: Double = 0.5
        
        var P: [String] = []
        var M: [String] = []
        var C: [String] = []
        var T: [String] = []
        
        var Q: Double = 0
        
        mutating func calcQ() {
            let buffQ = CodeAnalyzer.Metrics.a1*Double(P.count) + CodeAnalyzer.Metrics.a2*Double(M.count) + CodeAnalyzer.Metrics.a3*Double(C.count) + CodeAnalyzer.Metrics.a4*Double(T.count)
            self = Metrics(P: P, M: M, C: C, T: T, Q: buffQ)
        }
        
        func getQStr() -> String {
            var ret: String = ""
            ret = ret + String(CodeAnalyzer.Metrics.a1)
            ret = ret + "*"
            ret = ret + String(P.count)
            ret = ret + " + "
            ret = ret + String(CodeAnalyzer.Metrics.a2)
            ret = ret + "*"
            ret = ret + String(M.count)
            ret = ret + " + "
            ret = ret + String(CodeAnalyzer.Metrics.a3)
            ret = ret + "*"
            ret = ret + String(C.count)
            ret = ret + " + "
            ret = ret + String(CodeAnalyzer.Metrics.a4)
            ret = ret + "*"
            ret = ret + String(T.count)
            ret = ret + " = " + String(Q)
            return ret
        }
    }
    
    private struct CodeBlock {
        var title: String = ""
        var code: String = ""
        var variables: [ScalaVariable] = []
        var STDMetrics: Metrics = Metrics()
        var IOMetrics: Metrics = Metrics()
        var defBlocks: [String:CodeBlock] = [:]
    }
    
    private let code: String!
    private var objectBlock: CodeBlock!
    
    private let commentPattern = #"(\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\/)|(\/\/.*)"#
    private let blankLinePattern = #"[\r\n\t][\r\n\t ]*[\r\n]"#
    private let repeatingSpecesPattern = #" {2,}"#
    private let floatingSpecesPattern = #"[\r\n][\n\r\t ]*"#
    private let ternaryOperatorPattern = #"[^\n\r{}]+\?[^\n\r]*:[^\n\r{}]*"#
    private let complexOperatorPattern = #"(\w+ *)(\(.*\))"#
    private let closedComplexOperatorPattern = #"\.?\w*\([^()]*\)"#
    private let stringPattern = #"\"[^"]*\""#
    private let matchBlockBeginningPattern = #"[\w]+ (match) ?\{"#
    private let ifBlockBeginningPattern = #"(if) ?\([\w=<>()+\-*/ ]+\) ?\{"#
    private let variableInitializationPattern = #"(var|val) [a-zA-Z][\w\d]*( ?= ?((([\w\d+\-][\w\d><(),%+\-*/ ]*(\.[\w\d]+(\([\w\d]*\))?)*)|("[\w\d ]*")))|(( ?: ?\w+ ?= ?((([\w\d+\-][\w\d><(),%+\-*/ ]*(\.[\w\d]+(\([\w\d]*\))?)*)|("[\w\d ]*"))))|( ?: ?\w+)))"#
    private let variableTypePattern = #" ?: ?[\w\[\]]+ ?"#
    private let variableModificationPattern = #"\w+ ?=[^=]"# // Finds 1 more symbol after =
    private let variableNamePattern = #"[a-zA-Z][a-zA-Z0-9]*"#
    private let variableOutputPattern = #"(Console\.println)"#
    private let variableInputPattern = #"(\w+) ?= ?(Console\.read)"#
    
    private let objectBlockBeginningPattern = #"(object) \w+ ?\{"#
    private let defBlockBeginningPattern = #"(def) \w+( ?\(.*\))? ?\{"#
    
    private let objectBlockName = "object"
    private let functionBlockName = "def"
    
    private let simpleOperators: [String] = ["<<=",">>=","<<<",">>>","<<",">>","&&","||","==","!=","^=","|=","&=","%=","/=","*=","+=","-=",">=","<=","~","&","|","^","!","=",">","<","+","-","*","/","%",";",","]
    
    
    init(s: String) {
        if CodeAnalyzer.checkCodeForParentheses(s: s) {
            code = s
            print("-> Source code is valid!")
        } else {
            code = ""
            print("-> There are some errors in the source code. Resetting code to blank string!")
        }
        updateObjectBlock()
    }
    
    private static func checkCodeForParentheses(s: String) -> Bool {
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
        s = s.replacingOccurrences(of: blankLinePattern, with: "\n", options: .regularExpression, range: nil)
    }
    
    private func removeRepeatingSpaces(s: inout String){
        s = s.replacingOccurrences(of: repeatingSpecesPattern, with: " ", options: .regularExpression, range: nil)
    }
    
    private func removeStringLiterals(s: inout String){
        s = s.replacingOccurrences(of: stringPattern, with: "", options: .regularExpression, range: nil)
    }
    
    private func removeFloatingSpaces(s: inout String){
        s = s.replacingOccurrences(of: floatingSpecesPattern, with: "\n", options: .regularExpression, range: nil)
    }
    
    private func getBlockRange(st_index: String.Index, in str: String, o_sign: Character, c_sign: Character) -> Range<String.Index>?{
        var ret: Range<String.Index>? = nil
        
        let p1: String.Index = st_index
        var p2: String.Index = st_index
        while p2 < str.endIndex && str[p2] != o_sign {
            p2 = str.index(after: p2)
        }
        if p2 < str.endIndex {
            var i: Int = 1
            p2 = str.index(after: p2)
            
            while p2 < str.endIndex && i>0{
                switch str[p2] {
                case o_sign:
                    i = i + 1
                case c_sign:
                    i = i - 1
                default:
                    break
                }
                p2 = str.index(after: p2)
            }
            
            if i == 0 {
                ret = p1..<p2
            }
        }
        
        return ret
    }
    
    private func extractTitleFromBlockRange(st_index: String.Index, in str: String, o_sign: Character) -> String {
        var ret: String = ""
        
        let p1: String.Index = st_index
        var p2: String.Index = st_index
        while p2 < str.endIndex && str[p2] != o_sign {
            p2 = str.index(after: p2)
        }
        if p2 != str.endIndex {
            p2 = str.index(after: p2)
        }
        ret = String(str[p1..<p2])
        return ret
    }
    
    private func getSearchRange(of str: String) -> Range<String.Index> {
        var ret: Range<String.Index> = str.endIndex..<str.endIndex
        guard var p1: String.Index = str.firstIndex(of: "{") else {
            return ret
        }
        guard let p2: String.Index = str.lastIndex(of: "}") else {
            return ret
        }
        if p1<p2 {
            p1 = str.index(after: p1)
            ret = p1..<p2
        }
        return ret
    }
    
    private func updateDefBlocksRecursion(of block: inout CodeBlock){
        var buffStr: String = block.code
        
        var searchRange: Range<String.Index> = getSearchRange(of: buffStr)
        var buffRng: Range<String.Index>? = nil
        buffRng = buffStr.range(of: defBlockBeginningPattern, options: .regularExpression, range: searchRange)
        while buffRng != nil {
            buffRng = getBlockRange(st_index: buffRng!.lowerBound, in: buffStr, o_sign: "{", c_sign: "}")
            let buffTitle: String = extractTitleFromBlockRange(st_index: buffRng!.lowerBound, in: buffStr, o_sign: "{")
            let buffBlock: CodeBlock = CodeBlock(title: buffTitle, code: String(buffStr[buffRng!]), defBlocks: [:])
            block.defBlocks.updateValue(buffBlock, forKey: buffTitle)
            print("Found block with title: \"\(buffTitle)\"   (-> \"\(block.title)\")")
            buffStr.removeSubrange(buffRng!)
            
            searchRange = getSearchRange(of: buffStr)
            buffRng = buffStr.range(of: defBlockBeginningPattern, options: .regularExpression, range: searchRange)
        }
        normalizeCode(of: &buffStr)
        block.code = buffStr
//        print(block.code)

        block.defBlocks.keys.forEach { (blockKey) in
            updateDefBlocksRecursion(of: &(block.defBlocks[blockKey])!)
        }
        
    }
    
    private func setTitlesToVariables(of block: inout CodeBlock){
        if block.variables.count > 0 {
            for i in 0...block.variables.count-1 {
                var buffTitle: String = block.variables[i].initString
                buffTitle.removeFirst(4)
                if let buffRng: Range<String.Index> = buffTitle.range(of: variableTypePattern, options: .regularExpression) {
                    buffTitle.removeSubrange(buffRng)
                }
                buffTitle = buffTitle.replacingOccurrences(of: " ", with: "")
                if let p: String.Index = buffTitle.firstIndex(of: "=") {
                    buffTitle.removeSubrange(p..<buffTitle.endIndex)
                }
                block.variables[i].name = buffTitle
            }
        }
    }
    
    private func extractVariablesFormComplexOperator(in str: inout String) -> [String]{
        var variables: [String] = []
        var rng: Range<String.Index>? = nil
        rng = str.range(of: closedComplexOperatorPattern, options: .regularExpression)
        while rng != nil {
            var buffTitle: String = String(str[rng!])
            buffTitle.removeSubrange(buffTitle.startIndex...buffTitle.firstIndex(of: "(")!)
            buffTitle.removeLast()
            var opRng: Range<String.Index>? = nil
            opRng = buffTitle.range(of: variableNamePattern, options: .regularExpression)
            while opRng != nil {
                variables.append(String(buffTitle[opRng!]))
                buffTitle.removeSubrange(opRng!)
                opRng = buffTitle.range(of: variableNamePattern, options: .regularExpression)
            }
            str.removeSubrange(rng!)
            rng = str.range(of: closedComplexOperatorPattern, options: .regularExpression)
        }
        rng = str.range(of: variableNamePattern, options: .regularExpression)
        while rng != nil {
            variables.append(String(str[rng!]))
            str.removeSubrange(rng!)
            rng = str.range(of: variableNamePattern, options: .regularExpression)
        }
        return variables
    }
    
    private func extractVariablesDataFromInitString(of block: inout CodeBlock){
        var operatorVariables: [String] = []
        if block.variables.count > 0 {
            for i in 0...block.variables.count-1 {
                var buffStr: String = block.variables[i].initString
                if let p: String.Index = buffStr.firstIndex(of: "=") {
                    buffStr = String(buffStr[p..<buffStr.endIndex])
                    buffStr = buffStr.replacingOccurrences(of: #"= *"#, with: "", options: .regularExpression)
                    removeStringLiterals(s: &buffStr)
                    removeFloatingSpaces(s: &buffStr)
                    if !buffStr.isEmpty {
                        buffStr = buffStr.replacingOccurrences(of: " ", with: "")
                        if buffStr.range(of: "Console.read") != nil {
                            block.variables[i].isInputVariable = true
                        }
                        operatorVariables = operatorVariables + extractVariablesFormComplexOperator(in: &buffStr)
                    }
                }
            }
            for i in 0...block.variables.count-1 {
                operatorVariables.forEach { (v) in
                    if v == block.variables[i].name {
                        block.variables[i].wasUsed = true
                    }
                }
            }
        }
    }
    
    private func findControlVariables(in str: String, upd variablesArray: inout [ScalaVariable]){
        var operatorVariables: [String] = []
        var buffStr: String = str
        var rng: Range<String.Index>? = nil
        rng = buffStr.range(of: ifBlockBeginningPattern, options: .regularExpression)
        while rng != nil {
            var additionalBuffStr: String = String(buffStr[rng!])
            additionalBuffStr.removeFirst(2)
            operatorVariables = operatorVariables + extractVariablesFormComplexOperator(in: &additionalBuffStr)
            buffStr.replaceSubrange(rng!, with: "{")
            rng = buffStr.range(of: ifBlockBeginningPattern, options: .regularExpression)
        }
        if variablesArray.count > 0 {
            for i in 0...variablesArray.count-1 {
                operatorVariables.forEach { (v) in
                    if v == variablesArray[i].name {
                        variablesArray[i].isControlVariable = true
                    }
                }
            }
        }
    }
    
    private func findModifiedVariables(in str: inout String, upd variablesArray: inout [ScalaVariable]){
        var modifiedVariables: [String] = []
        
        var rng: Range<String.Index>? = nil
        rng = str.range(of: variableModificationPattern, options: .regularExpression)
        while rng != nil {
            var buffStr: String = String(str[rng!])
            let lastSymbol: Character = buffStr.last!
            buffStr = String(buffStr[buffStr.startIndex..<buffStr.firstIndex(of: "=")!])
            buffStr = buffStr.replacingOccurrences(of: " ", with: "")
            modifiedVariables.append(buffStr)
            str.replaceSubrange(rng!, with: String(lastSymbol))
            rng = str.range(of: variableModificationPattern, options: .regularExpression)
        }
        if variablesArray.count > 0 {
            for i in 0...variablesArray.count-1 {
                modifiedVariables.forEach { (v) in
                    if v == variablesArray[i].name {
                        variablesArray[i].wasModified = true
                    }
                }
            }
        }
    }
    
    private func findUsedVariables(in str: String, upd variablesArray: inout [ScalaVariable]){
        var usedVariables: [String] = []
        var buffStr: String = str
        var rng: Range<String.Index>? = nil
        rng = buffStr.range(of: variableNamePattern, options: .regularExpression)
        while rng != nil {
            usedVariables.append(String(buffStr[rng!]))
            buffStr.removeSubrange(rng!)
            rng = buffStr.range(of: variableNamePattern, options: .regularExpression)
        }
        if variablesArray.count > 0 {
            for i in 0...variablesArray.count-1 {
                usedVariables.forEach { (v) in
                    if v == variablesArray[i].name {
                        variablesArray[i].wasUsed = true
                    }
                }
            }
        }
    }
    
    private func countVariableSpen(in str: String, upd variablesArray: inout [ScalaVariable]){
        var spennableVariables: [String] = []
        var buffStr: String = str
        var rng: Range<String.Index>? = nil
        rng = buffStr.range(of: variableNamePattern, options: .regularExpression)
        while rng != nil {
            spennableVariables.append(String(buffStr[rng!]))
            buffStr.removeSubrange(rng!)
            rng = buffStr.range(of: variableNamePattern, options: .regularExpression)
        }
        if variablesArray.count > 0 {
            for i in 0...variablesArray.count-1 {
                spennableVariables.forEach { (v) in
                    if v == variablesArray[i].name {
                        variablesArray[i].spen = variablesArray[i].spen + 1
                    }
                }
            }
        }
    }
    
    private func findOutputVariables(in str: String, upd variablesArray: inout [ScalaVariable]){
        var outputVariables: [String] = []
        var buffStr: String = str
        var rng: Range<String.Index>? = nil
        rng = buffStr.range(of: variableOutputPattern, options: .regularExpression)
        while rng != nil {
            if let blockRng: Range<String.Index> = getBlockRange(st_index: rng!.lowerBound, in: buffStr, o_sign: "(", c_sign: ")") {
                var s: String = String(buffStr[blockRng])
                outputVariables = outputVariables + extractVariablesFormComplexOperator(in: &s)
            }
            buffStr.removeSubrange(rng!)
            rng = buffStr.range(of: variableOutputPattern, options: .regularExpression)
        }
        buffStr = str
        rng = buffStr.range(of: variableInputPattern, options: .regularExpression)
        while rng != nil {
            var s: String = String(buffStr[rng!])
            outputVariables = outputVariables + extractVariablesFormComplexOperator(in: &s)
            buffStr.removeSubrange(rng!)
            rng = buffStr.range(of: variableInputPattern, options: .regularExpression)
        }
        if variablesArray.count > 0 {
            for i in 0...variablesArray.count-1 {
                outputVariables.forEach { (v) in
                    if v == variablesArray[i].name {
                        variablesArray[i].isOutputVariable = true
                    }
                }
            }
        }
    }
    
//    private func getMetricsGroup(of v: ScalaVariable) -> [Metric_Group] {
//        var ret: [Metric_Group] = []
//        if v.isControlVariable {
//            ret = ret + [.C]
//        } else {
//            if (!v.wasUsed) {
//                ret = ret + [.T]
//            }
//            if v.isInputVariable && !v.wasModified {
//                ret = ret + [.P]
//            } else {
//                ret = ret + [.M]
//            }
//        }
//        return ret
//    }
    
    // No M and T intersection
    private func getMetricsGroup(of v: ScalaVariable) -> [Metric_Group] {
        var ret: [Metric_Group] = []
        if v.isControlVariable {
            ret = ret + [.C]
        } else {
            if v.isInputVariable && !v.wasModified {
                ret = ret + [.P]
                if !v.wasUsed {
                    ret = ret + [.T]
                }
            } else {
                if v.wasUsed {
                    ret = ret + [.M]
                } else {
                    ret = ret + [.T]
                }
            }
        }
        return ret
    }
    
    private func updateMetrics(of block: inout CodeBlock){
        block.variables.forEach { (v) in
            let VGroups: [Metric_Group] = getMetricsGroup(of: v)
            VGroups.forEach { (grp) in
                switch grp {
                case .P:
                    block.STDMetrics.P.append(v.name)
                    if v.isInputVariable || v.isOutputVariable {
                        block.IOMetrics.P.append(v.name)
                    }
                case .M:
                    block.STDMetrics.M.append(v.name)
                    if v.isInputVariable || v.isOutputVariable {
                        block.IOMetrics.M.append(v.name)
                    }
                case .C:
                    block.STDMetrics.C.append(v.name)
                    if v.isInputVariable || v.isOutputVariable {
                        block.IOMetrics.C.append(v.name)
                    }
                case .T:
                    block.STDMetrics.T.append(v.name)
                    if v.isInputVariable || v.isOutputVariable {
                        block.IOMetrics.T.append(v.name)
                    }
                }
            }
        }
        block.STDMetrics.calcQ()
        block.IOMetrics.calcQ()
    }
    
    private func analyzeVariablesRecursion(of block: inout CodeBlock){
        setTitlesToVariables(of: &block)
        extractVariablesDataFromInitString(of: &block)
        countVariableSpen(in: block.code, upd: &block.variables)
        var buffStr: String = block.code
        
        buffStr = buffStr.replacingOccurrences(of: "while", with: "if")
        buffStr = buffStr.replacingOccurrences(of: "for", with: "if")
        buffStr = buffStr.replacingOccurrences(of: variableInitializationPattern, with: "", options: .regularExpression)
        normalizeCode(of: &buffStr)
        
        findOutputVariables(in: buffStr, upd: &block.variables)
        findControlVariables(in: buffStr, upd: &block.variables)
        findModifiedVariables(in: &buffStr, upd: &block.variables)
        findUsedVariables(in: buffStr, upd: &block.variables)
        normalizeCode(of: &buffStr)
        
        updateMetrics(of: &block)
        
        block.defBlocks.keys.forEach { (blockKey) in
            analyzeVariablesRecursion(of: &(block.defBlocks[blockKey])!)
        }
    }
    
    private func updateObjectBlock(){
        objectBlock = CodeBlock(code: "", defBlocks: [:])
        
        if let objRng: Range<String.Index> = code.range(of: objectBlockBeginningPattern, options: .regularExpression){
            if let extObjRng: Range<String.Index> = getBlockRange(st_index: objRng.lowerBound, in: code, o_sign: "{", c_sign: "}") {
                objectBlock.code = String(code[extObjRng])
                objectBlock.title = extractTitleFromBlockRange(st_index: objectBlock.code.startIndex, in: objectBlock.code, o_sign: "{")
                updateDefBlocksRecursion(of: &objectBlock)
                updateVariablesDataRecursion(of: &objectBlock)
                analyzeVariablesRecursion(of: &objectBlock)
            }
        }
    }
    
    private func extractDefParameters(of block: inout CodeBlock){
        if let p1: String.Index = block.title.firstIndex(of: "(") {
            if let p2: String.Index = block.title.lastIndex(of: ")") {
                var str: String = String(block.title[p1...p2])
                str = str.replacingOccurrences(of: variableTypePattern, with: "", options: .regularExpression)
                let operatorVariables: [String] = extractVariablesFormComplexOperator(in: &str)
                operatorVariables.forEach { (v) in
                    block.variables.append(ScalaVariable(initString: "val " + v + ":Auto", name: v))
                }
            }
        }
    }
    
    private func updateVariablesDataRecursion(of block: inout CodeBlock){
        extractDefParameters(of: &block)
        var buffStr: String = block.code
        
        var rng: Range<String.Index>? = nil
        rng = buffStr.range(of: variableInitializationPattern, options: .regularExpression)
        while rng != nil {
            let buffTitle: String = String(buffStr[rng!])
            print("Found variable with title: \"\(buffTitle)\"")
            let buffVariable: ScalaVariable = ScalaVariable(initString: buffTitle)
            block.variables.append(buffVariable)
            buffStr.removeSubrange(rng!)
            rng = buffStr.range(of: variableInitializationPattern, options: .regularExpression)
        }
        
        block.defBlocks.keys.forEach { (blockKey) in
            updateVariablesDataRecursion(of: &(block.defBlocks[blockKey])!)
        }
    }
    
    private func normalizeCode(of str: inout String){
        removeComments(s: &str)
        removeBlankLines(s: &str)
        removeRepeatingSpaces(s: &str)
        removeFloatingSpaces(s: &str)
    }
    
    private func outputVariablesRecursion(of block: inout CodeBlock){
        block.variables.forEach { (v) in
            print()
            print("Init str:", v.initString)
            print("Name:", v.name)
            print("Spen:", v.spen)
            print("Was modified? -", v.wasModified)
            print("Was used? -", v.wasUsed)
            print("Is control variable? -", v.isControlVariable)
            print("Is input variable? -", v.isInputVariable)
            print("Is output variable? -", v.isOutputVariable)
        }
        block.defBlocks.keys.forEach { (blockKey) in
            outputVariablesRecursion(of: &(block.defBlocks[blockKey])!)
        }
            
    }
    
    private func outputMetricsRecursion(of block: inout CodeBlock){
        
        print()
        print("Block: \"\(block.title)\"")
        print("STD_P:", block.STDMetrics.P)
        print("STD_M:", block.STDMetrics.M)
        print("STD_C:", block.STDMetrics.C)
        print("STD_T:", block.STDMetrics.T)
        print("STD_Q:", block.STDMetrics.Q)
        print(" IO_P:", block.IOMetrics.P)
        print(" IO_M:", block.IOMetrics.M)
        print(" IO_C:", block.IOMetrics.C)
        print(" IO_T:", block.IOMetrics.T)
        print(" IO_Q:", block.IOMetrics.Q)
        
        block.defBlocks.keys.forEach { (blockKey) in
            outputMetricsRecursion(of: &(block.defBlocks[blockKey])!)
        }
    }
    
    private func findEntryBlock(in block: inout CodeBlock, result: inout CodeBlock){
        if block.title.contains("def main") {
            result = block
        }
        block.defBlocks.keys.forEach { (blockKey) in
            findEntryBlock(in: &(block.defBlocks[blockKey])!, result: &result)
        }
    }
    
    func getSpenOutputStr() -> String {
        var ret: String = ""
        var block: CodeBlock = CodeBlock()
        findEntryBlock(in: &objectBlock, result: &block)
        var sumSpen: Int = 0
        block.variables.forEach { (v) in
            ret = ret + v.name + "\u{00a0}=\u{00a0}" + String(v.spen) + ", "
            sumSpen = sumSpen + v.spen
        }
        if !ret.isEmpty {
            ret.removeLast(2)
        }
        ret = ret + "\nОбщий спен = " + String(sumSpen)
        return ret
    }
    
    func getChepinFullStr() -> String {
        var ret: String = ""
        var tStr: String = ""
        let padValue: Int = 7
        var block: CodeBlock = CodeBlock()
        var added: Bool = false
        findEntryBlock(in: &objectBlock, result: &block)
        tStr = "P(\(block.STDMetrics.P.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.STDMetrics.P.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        added = false
        tStr = "M(\(block.STDMetrics.M.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.STDMetrics.M.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        added = false
        tStr = "C(\(block.STDMetrics.C.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.STDMetrics.C.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        added = false
        tStr = "T(\(block.STDMetrics.T.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.STDMetrics.T.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        ret = ret + "\n"+"Q:".padding(toLength: padValue, withPad: " ", startingAt: 0) + block.STDMetrics.getQStr()
        return ret
    }
    
    func getChepinIOStr() -> String {
        var ret: String = ""
        var tStr: String = ""
        let padValue: Int = 7
        var block: CodeBlock = CodeBlock()
        var added: Bool = false
        findEntryBlock(in: &objectBlock, result: &block)
        tStr = "P(\(block.IOMetrics.P.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.IOMetrics.P.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        added = false
        tStr = "M(\(block.IOMetrics.M.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.IOMetrics.M.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        added = false
        tStr = "C(\(block.IOMetrics.C.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.IOMetrics.C.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        added = false
        tStr = "T(\(block.IOMetrics.T.count)):".padding(toLength: padValue, withPad: " ", startingAt: 0)
        ret = ret + "\n" + tStr
        block.IOMetrics.T.forEach { (s) in
            added = true
            ret = ret + s + ", "
        }
        if added {
            ret.removeLast(2)
        }
        ret = ret + "\n"+"Q:".padding(toLength: padValue, withPad: " ", startingAt: 0) + block.IOMetrics.getQStr()
        return ret
    }
    
    func outputMetrics(){
        outputMetricsRecursion(of: &objectBlock)
    }
    
    func outputVariables(){
        outputVariablesRecursion(of: &objectBlock)
    }
    
    func outputCode(){
        print("Code:")
        print(code!)
    }
    
}




