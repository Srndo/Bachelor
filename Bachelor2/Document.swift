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
    var documentPath: URL
    
    init(protoID: Int, proto: Proto? = nil) {
        self.proto = proto
        
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        documentPath = path.appendingPathComponent("Documents").appendingPathComponent(String(protoID) + ".json")
        
        super.init(fileURL: documentPath)
    }
    
    /**
        Encode protocol to string.
     */
    override func contents(forType typeName: String) throws -> Any {
        do {
            return try JSONEncoder().encode(proto)
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
            printError(from: "document load", message: "Cannot decode protocol")
        }
    }
    
    func delete() throws {
        try FileManager.default.removeItem(at: documentPath)
    }
}
