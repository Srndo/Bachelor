//
//  Extensions.swift
//  Bachelor2
//
//  Created by Simon Sestak on 23/03/2021.
//

import SwiftUI

public func printError(from: String, message: String){
    print("ERROR [\(from)]: \(message)")
}

extension Proto {
    func disabled() -> Bool {
        if creationDate != nil && client.filled() && construction.filled() && device.filled() && method.filled() && material.filled() {
            return false
        }
        return true
    }
}

extension Material {
    func filled() -> Bool {
        return !material.isEmpty
    }
}

extension MyMethod {
    func filled() -> Bool {
        return !(name.isEmpty || requestedValue <= 0.0)
    }
}

extension Device {
    func filled() -> Bool {
        return !(serialNumber.isEmpty || name.isEmpty || manufacturer.isEmpty)
    }
}

extension Construction {
    func filled() -> Bool {
        return !(name.isEmpty || address.isEmpty)
    }
}

extension Company {
    func filled() -> Bool {
        return !(ico <= 0 || dic <= 0 || name.isEmpty || address.isEmpty)
    }
}

extension Photo {
    mutating func saveToDisk(photo: UIImage?, name: String) {
        guard let img = photo else { printError(from: "save photo", message: "\(name) for save is nil"); return }
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { printError(from: "save photo", message: "Documents directory is nil"); return }
        
        self.name = name
        self.relativePath = "Images/" + name + ".png"
        let imagePath = docURL.appendingPathComponent(self.relativePath)
        
        DispatchQueue.global().async {
            guard let data = img.jpegData(compressionQuality: 0.1) else { printError(from: "save photo", message: "Cannot convert \(name) to data"); return }
            
            do {
                try data.write(to: imagePath)
            } catch {
                printError(from: "save photo", message: "Cannot write \(name) to disk")
                print(error)
                return
            }
            print("Photo \(name) saved")
        }
    }
    
    func asynLoadFromDisk(completitionBlock: @escaping (Image) -> ()) {
        DispatchQueue.global().async {
            guard self.relativePath != "" else { printError(from: "photo load", message: "Path of \(self.name) is empty"); return }
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { printError(from: "photo load", message: "Documents directory is nil"); return }
            
            let imagePath = docURL.appendingPathComponent(self.relativePath)
            if let uiimage = UIImage(contentsOfFile: imagePath.path){
                DispatchQueue.main.async {
                    completitionBlock(Image(uiImage: uiimage))
                }
            }
            DispatchQueue.main.async {
                completitionBlock(Image(systemName: "photo"))
            }
        }
    }
    
    func deleteFromDisk() {
        DispatchQueue.global().async {
            printError(from: "delete photo", message: "Cannot delete \(self.name) from disk")
            guard self.relativePath != "" else { printError(from: "delete photo", message: "Path of \(self.name) is empty"); return }
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { printError(from: "delete photo", message: "Documents directory is nil"); return }
            
            let url = docURL.appendingPathComponent(self.relativePath)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                printError(from: "delete photo", message: "Cannot delete \(self.name) from disk")
                print(error)
                return
            }
            print("Photo deleted")
        }
    }
}

extension ProtocolView {
    private func save(from: String, message: String, errorViewMessage: String) {
        do {
            try moc.save()
        } catch {
            printError(from: from, message: message)
            self.message = errorViewMessage
            print(error)
        }
    }
    
    func createNew() {
        self.document = Document(protoID: proto.id, proto: proto)
        guard let document = document else { printError(from: "protoView-document", message: "Document is nil"); return }
        let path = document.documentPath
        
        document.save(to: path, for: .forCreating, completionHandler: { (res: Bool) in
            print(res ? "Document saved " : "ERROR [UIDoc]: Cannot save document")
            let newDA = DatabaseArchive(context: moc)
            let encodedProto = newDA.fillWithData(proto: proto, local: true)
            guard let encoded = encodedProto else { printError(from: "UIDoc", message: "Cannot save to cloud, encodedProto is nil"); return }
            
            Cloud.save(protoID: proto.id, encodedProto: encoded, completition: { result in
                switch result {
                case .failure(let err):
                    printError(from: "cloud save", message: "Protocol not saved into cloud")
                    print(err)
                    return
                    
                case .success(let element):
                    newDA.recordID = element.recordID
                    save(from: "cloud save", message: "RecordID not saved", errorViewMessage: "ERROR: Protokol sa nepodarilo zalohovať na cloud")
                }
            })
            
            save(from: "UIDoc", message: "Protocol not saved into core data", errorViewMessage: "ERROR: Protokol sa nepodarilo uložiť")
            self.proto = Proto(id: -1)
            self.ico = ""
            self.dic = ""
            self.reqVal = "" 
            self.message = "Protokol uložený"
        })
    }
    
    // MARK: TODO: Internal ID not upadeted 
    func modify() {
        guard let document = document else { printError(from: "cloud modify", message: "Document is nil"); return }
        let DA = DAs.first(where: { $0.protoID == Int16(proto.id) })!
        guard let recordID = DA.recordID else { printError(from: "modify", message: "Record.ID of protocol[\(proto.id)] is nil"); return }
        
        self.proto.internalID = proto.internalID + 1
        self.internalID = proto.internalID
        let _ = DA.fillWithData(proto: proto, local: true, recordID: recordID)
        document.proto = proto
        document.updateChangeCount(.done)
        document.save(to: document.documentPath, for: .forOverwriting){ res in
            if res == true {
                print("Document with protocol \(proto.id) overwrited")
            } else {
                printError(from: "cloud fetch", message: "Document with protocol \(proto.id) did not overwrited")
            }
        }
        

        // MARK: Cloud modify
        Cloud.modify(item: proto, recordID: recordID){ res in
            switch res {
                case .failure(let err):
                    printError(from: "cloud modify", message: err.localizedDescription)
                    return
                case .success(_):
                    
                    print("Element modified on cloud")
                    return
            }
            
        }
        save(from: "modify", message: "Cannot save modified proto", errorViewMessage: "ERROR: Zmeny sa nepodarilo uložiť")
        self.message = "Zmeny uložené"
    }
    
    func openDocument() {
        guard protoID != -1 else { return }
        document = Document(protoID: protoID)
        guard let document = document else { printError(from: "protoView-document", message: "Document is nil"); return }
        
        document.open { res in
            if res {
                print("Document with protocol \(protoID) opened.")
                DispatchQueue.main.async {
                    guard let proto = document.proto else { printError(from: "protoView-document", message: "Document protocol is nil"); return }
                    self.proto = proto
                    self.ico = String(proto.client.ico)
                    self.dic = String(proto.client.dic)
                    self.reqVal = String(proto.method.requestedValue)
                    self.internalID = proto.internalID
                }
            } else {
                printError(from: "protoView-document", message: "Document with protocol \(protoID) did not open")
            }
        }
    }
    
    func closeDocument() {
        if let document = document {
                document.close{ res in
                    if res {
                        print("Document with protocol \(protoID) closed")
                    } else {
                        printError(from: "protoView-document", message: "Document with protocol \(protoID) did not closed")
                    }
                    
                }
        }
    }
}
