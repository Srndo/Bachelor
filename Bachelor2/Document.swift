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
        let path = Dirs.shared.getProtosDir()!
        documentPath = path.appendingPathComponent(String(protoID) + ".json")
        
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
        if FileManager.default.fileExists(atPath: documentPath.path){
            try FileManager.default.removeItem(at: documentPath)
        }
    }
    
    func modify(new proto: Proto) {
        self.proto = proto
        self.updateChangeCount(.done)
        self.save(to: documentPath, for: .forOverwriting) { res in
            if res {
                print("Document with protocol \(proto.id) overwrited")
            } else {
                printError(from: "document overwrite", message: "Document with protocol \(proto.id) did not overwrited")
            }
        }
    }
    
    func createNew(completition: (() -> ())? ) {
        guard let proto = proto else { printError(from: "document save", message: "Protocol is nil"); return }
        
        self.save(to: documentPath, for: .forCreating) { res in
            if res {
                print("Document with protocol \(proto.id) saved")
                if let completition = completition {
                    completition()
                }
            } else {
                printError(from: "document save", message: "Cannot save document with protocol \(proto.id)")
            }
        }
    }
}
