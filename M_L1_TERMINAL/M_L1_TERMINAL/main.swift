//
//  main.swift
//  M_L1_TERMINAL
//
//  Created by Михаил Ковалевский on 27/09/2019.
//  Copyright © 2019 Mikhail Kavaleuski. All rights reserved.
//

import Foundation

func main() -> Int{
    
    var source: String = ""
    
    do {
        source = try String(contentsOf: Bundle.main.url(forResource: "src", withExtension: "scala")!)
        print("Succesfuly loaded source code!")
    } catch let err {
        fatalError(err.localizedDescription)
    }
    
    
    return 0
}

let result = main()
print("Main func return code:", result)


