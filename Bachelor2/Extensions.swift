//
//  Extensions.swift
//  Bachelor2
//
//  Created by Simon Sestak on 23/03/2021.
//

import SwiftUI
import CloudKit
import CoreData.NSManagedObjectContext

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

extension ProtocolView {
    func createNew() {
        self.document = Document(protoID: proto.id, proto: proto)
        guard let document = document else { printError(from: "protoView-document", message: "Document is nil"); return }
        
        // crate new document including protocol
        document.createNew{
            // after succesfull creation of document
            // fill database with this protocol
            let newDA = DatabaseArchive(context: moc)
            let encodedProto = newDA.fillWithData(proto: proto, local: true)
            guard let encoded = encodedProto else {
                printError(from: "UIDoc", message: "Cannot save to cloud, encodedProto is nil")
                return
            }
            
            // save this encoded protocol to cloud
            Cloud.shared.saveToCloud(recordType: Cloud.RecordType.protocols, protoID: proto.id, encodedProto: encoded) { recordID in
                // after succesfull cloud save, insert recordID into database
                newDA.recordID = recordID
                save(from: "cloud save", error: "RecordID not saved", errorViewMessage: "ERROR: Protokol sa nepodarilo zalohovať na cloud")
            }
            save(from: "UIDoc", error: "Protocol not saved into core data", errorViewMessage: "ERROR: Protokol sa nepodarilo uložiť")
            self.proto = Proto(id: -1)
            self.ico = ""
            self.dic = ""
            self.reqVal = ""
            self.message = "Protokol uložený"
        }
    }
    
    func modify() {
        guard let document = document else { printError(from: "modify", message: "Document is nil"); return }
        guard let DA = DAs.first(where: { $0.protoID == Int16(proto.id) }) else { printError(from: "modify", message: "Protocol for modifying is not in database"); return }
        guard let recordID = DA.recordID else { printError(from: "modify", message: "Record.ID of protocol[\(proto.id)] is nil"); return }
        let _ = DA.fillWithData(proto: proto, local: true, recordID: recordID)
        document.modify(new: proto)
        
        Cloud.shared.modifyOnCloud(recordID: recordID, proto: proto)
        
        save(from: "modify", error: "Cannot save modified proto", errorViewMessage: "ERROR: Zmeny sa nepodarilo uložiť")
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
    
    func createOutput(protoID: Int) {
        self.proto.internalID = proto.internalID + 1
        self.internalID = proto.internalID
        
        modify() // save incremented proto.id
        
        // MARK: TODO: wait until document saved
        createProtoPDF(protoID: protoID)
        createPhotosZIP(protoID: protoID)
    }
    
    private func createProtoPDF(protoID: Int) {
        // MARK: TODO: createProtoPDF
        print("Warning: Create protocol PDF")
        return
            
//        guard let outputURL = Dirs.shared.getSpecificOutputDir(protoID: protoID) else { return }
        // create PDF here
    }
    
    private func createPhotosZIP(protoID: Int) {
        // MARK: TODO createPhotosZIP
        print("Warning: Create ZIP with photos")
        return
        
//        guard let imagesURL = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return }
//
//        do {
//            let names = try FileManager.default.contentsOfDirectory(at: imagesURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
//        } catch {
//            printError(from: "cretePhotosZIP", message: error.localizedDescription)
//            return
//        }
//
//        guard let outputURL = Dirs.shared.getSpecificOutputDir(protoID: protoID) else { return }
        // create photo zip here
    }
    
    private func save(from: String, error message: String, errorViewMessage: String) {
        do {
            try moc.save()
        } catch {
            printError(from: from, message: message)
            self.message = errorViewMessage
            print(error)
        }
    }
}

extension ProtocolListView {
    func remove(at offSets: IndexSet) {
        for index in offSets {
            let remove = DAs[index]
            guard let recordID = remove.recordID else {
                printError(from: "remove protocol", message: "RecordID of protocol \(remove.protoID) is nil")
                return
            }
            // MARK: Cloud delete
            Cloud.shared.deleteFromCloud(recordID: recordID) { recordID in
                guard let recordID = recordID else { return }
                guard let removeCloud = DAs.first(where: { $0.recordID == recordID }) else {
                    printError(from: "remove cloud", message: "RecordID returned from cloud not exist in core data")
                    return
                }
                guard removeCloud == remove else {
                    printError(from: "remove cloud", message: "Marked protocol to remove and returned from cloud is not same")
                    return
                }
                removePhotos()
                removeDocument(protoID: Int(remove.protoID))
                moc.delete(remove)
                moc.trySave(errorFrom: "remove cloud", error: "Cannot saved managed object context")
            }
        }
    }
    
    func removeDocument(protoID: Int){
        let document = Document(protoID: protoID)
        
        if FileManager.default.fileExists(atPath: document.documentPath.path) {
            do {
                try document.delete()
                print("Document removed from local storage")
            } catch {
                printError(from: "remove document", message: "Cannot remove document for protocol[\(protoID)]")
                print(error)
            }
        }
    }
    
    func removePhotos(){
        // MARK: TODO
        print("Warning: Not removing photos")
    }
}

extension UserDefaults {
    var serverChangeToken: CKServerChangeToken? {
        get {
            guard let data = self.value(forKey: "changeToken") as? Data else { return nil }
            guard let token = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? CKServerChangeToken else { return nil }
            return token
        }
        set {
            if let token = newValue {
                guard let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: false) else {
                    self.removeObject(forKey: "changeToken")
                    return
                }
                self.setValue(data, forKey: "changeToken")
            } else {
                self.removeObject(forKey: "changeToken")
            }
        }
    }
}

extension NSManagedObjectContext {
    public func trySave(errorFrom: String, error message: String){
        do {
            try self.save()
        } catch {
            printError(from: errorFrom, message: message)
            print(error)
            return
        }
    }
}
