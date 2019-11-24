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
}

class CodeAnalyzer {
    private var code: String! = ""
    private var mainBlocks: CodeBlock! = CodeBlock(code: "", internalBlocks: [:])
    
    private let commentPattern = #"(\/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+\/)|(\/\/.*)"#
    private let blankLinePattern = #"[\r\n\t][\r\n\t ]*[\r\n]"#
    private let repeatingSpecesPattern = #" {2,}"#
    private let floatingSpecesPattern = #"[\r\n][\n\r\t ]*"#
    private let ternaryOperatorPattern = #"[^\n\r{}]+\?[^\n\r]*:[^\n\r{}]*"#
    private let complexOperatorPattern = #"(\w+ *)(\(.*\))"#
    private let stringPattern = #"\"[^"]*\""#
    private let matchBlockBeginningPattern = #"[\w]+ (match) ?{"#
    
    private let objectBlockName = "object"
    private let functionBlockName = "def"
    
    private let simpleOperators: [String] = ["<<=",">>=","<<<",">>>","<<",">>","&&","||","==","!=","^=","|=","&=","%=","/=","*=","+=","-=",">=","<=","~","&","|","^","!","=",">","<","+","-","*","/","%",";",","]
    
    
    init(s: String) {
        code = s
        removeComments(s: &code)
        removeBlankLines(s: &code)
        removeRepeatingSpaces(s: &code)
        removeFloatingSpaces(s: &code)
        
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
    
    func outputCode(){
        print("Code:")
        print(code!)
    }
    
}




