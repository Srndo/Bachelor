//
//  Document.swift
//  Bachelor2
//
//  Created by Simon Sestak on 18/03/2021.
//

import UIKit

enum DocumentErr: Error {
    case badCont
    case encErr
}

class Document: UIDocument {
    var proto: Proto?
    
    init(fileURL: URL, proto: Proto? = nil) {
        self.proto = proto
        super.init(fileURL: fileURL)
    }
    
    /**
        Encode protocol to string.
     */
    override func contents(forType typeName: String) throws -> Any {
        do {
            return try JSONEncoder().encode(proto).base64EncodedString()
        } catch {
            throw DocumentErr.encErr
        }
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else {
            throw DocumentErr.badCont
        }
        
        if let out = try? JSONDecoder().decode(Proto.self, from: data) {
            self.proto = out
        }
        else {
            self.proto = nil
            print("ERROR [document load]: Cannot decode protocol.")
        }
    }
}
