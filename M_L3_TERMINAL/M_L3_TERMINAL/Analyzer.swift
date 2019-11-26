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
        var spen: Int = 0
        var wasModified: Bool = false
        var wasUsed: Bool = false
        var isConsoleVariable: Bool = false
        var isControlVariable: Bool = false
    }
    
    private struct CodeBlock {
        var title: String = ""
        var code: String = ""
        var variables: [ScalaVariable] = []
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
    private let stringPattern = #"\"[^"]*\""#
    private let matchBlockBeginningPattern = #"[\w]+ (match) ?\{"#
    private let variableInitializationPattern = #"(var|val) [a-zA-Z][\w\d]*( ?= ?((([\w\d+\-][\w\d+\-*/ ]*(\.[\w\d]+(\([\w\d]*\))?)*)|("[\w\d]*")))|(( ?: ?\w+ ?= ?((([\w\d+\-][\w\d+\-*/ ]*(\.[\w\d]+(\([\w\d]*\))?)*)|("[\w\d]*"))))|( ?: ?\w+)))"#
    private let variableTypePattern = #" ?: ?\w+ ?"#
    private let variableModificationPattern = #"\w+ ?="#
    
//    #"(var|val) [a-zA-Z][\w\d]*( ?= ?((([\w\d]+)|("[\w\d]+")))|(( ?: ?\w+ ?= ?((([\w\d]+)|("[\w\d]+"))))|( ?: ?\w+)))"#
    
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
    
    private func extractVariablesDataFromInitString(of block: inout CodeBlock){
        if block.variables.count > 0 {
            for i in 0...block.variables.count-1 {
                var buffStr: String = block.variables[i].initString
                if let p: String.Index = buffStr.firstIndex(of: "=") {
                    buffStr = String(buffStr[p..<buffStr.endIndex])
//                    buffStr = buffStr.replacingOccurrences(of: #"= *"#, with: "", options: .regularExpression)
//                    removeStringLiterals(s: &buffStr)
                    print(buffStr)
                }
            }
        }
    }
    
    private func analyzeVariablesRecursion(of block: inout CodeBlock){
        setTitlesToVariables(of: &block)
        extractVariablesDataFromInitString(of: &block)
        var buffStr: String = block.code
//        buffStr = buffStr.replacingOccurrences(of: "while", with: "if")
//        buffStr = buffStr.replacingOccurrences(of: variableTypePattern, with: "", options: .regularExpression)
//        buffStr = buffStr.replacingOccurrences(of: "var ", with: "", options: .regularExpression)
//        buffStr = buffStr.replacingOccurrences(of: "val ", with: "", options: .regularExpression)
//        buffStr = buffStr.replacingOccurrences(of: #" *= *"#, with: " = ", options: .regularExpression)
        normalizeCode(of: &buffStr)
        print(buffStr)
        
//        var searchRange: Range<String.Index> = getSearchRange(of: buffStr)
//        var buffRng: Range<String.Index>? = nil
//        buffRng = buffStr.range(of: defBlockBeginningPattern, options: .regularExpression, range: searchRange)
//        while buffRng != nil {
//
//            searchRange = getSearchRange(of: buffStr)
//            buffRng = buffStr.range(of: defBlockBeginningPattern, options: .regularExpression, range: searchRange)
//        }

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
    
    private func updateVariablesDataRecursion(of block: inout CodeBlock){
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
            print("Is console variable? -", v.isConsoleVariable)
            print("Is control variable? -", v.isControlVariable)
        }
        block.defBlocks.keys.forEach { (blockKey) in
            outputVariablesRecursion(of: &(block.defBlocks[blockKey])!)
        }
            
    }
    
    func outputVariables(){
        outputVariablesRecursion(of: &objectBlock)
    }
    
    func outputCode(){
        print("Code:")
        print(code!)
    }
    
}




