//
//  main.swift
//  M_L3_TERMINAL
//
//  Created by Михаил Ковалевский on 24.11.2019.
//  Copyright © 2019 Михаил Ковалевский. All rights reserved.
//

import Foundation

func main() -> Int{
    
    var source: String = ""
    
    do {
        source = try String(contentsOf: Bundle.main.url(forResource: "src", withExtension: "scala")!)
        print("Succesfuly loaded source code!")
        print()
    } catch let err {
        fatalError(err.localizedDescription)
    }
    
    let Analyzer: CodeAnalyzer = CodeAnalyzer(s: source)
    Analyzer.outputCode()
    
    return 0
}

let result = main()
print()
print("Main func return code:", result)

