//
//  DatabaseArchive+CoreDataProperties.swift
//  Bachelor2
//
//  Created by Simon Sestak on 23/03/2021.
//
//

import Foundation
import CoreData


extension DatabaseArchive {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DatabaseArchive> {
        return NSFetchRequest<DatabaseArchive>(entityName: "DatabaseArchive")
    }

    @NSManaged public var client: String
    @NSManaged public var date: Date?
    @NSManaged public var local: Bool
    @NSManaged public var protoID: Int16
    @NSManaged public var recordID: CKRecord.ID?
    @NSManaged public var construction: String
    
    /**
        # Save to cloud
        Function saved object into cloud.
     */
    func saveToCloud() {
        self.getEncodedProto{ encoded in
            guard let proto = encoded else { return }
            Cloud.shared.saveToCloud(recordType: Cloud.RecordType.protocols, protoID: Int(self.protoID), encodedProto: proto) { recordID in
                self.recordID = recordID
            }
        }
    }
    
    /**
        # Remove document
        Function remove local copy of document.
     */
    func removeDocument() {
        let document = Document(protoID: Int(protoID))
        
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
    
    /**
        # Get encoded proto
        Function asynchronously return encoded document.
     */
    func getEncodedProto(completion: @escaping (String?) -> ()) {
        let document = Document(protoID: Int(protoID))
        document.open(){ res in
            if res {
                let encoded = try? JSONEncoder().encode(document.proto).base64EncodedString()
                completion(encoded)
            } else {
                completion(nil)
            }
            document.close()
        }
    }
    
    /**
        # Create
        Function will create or modify Document of this object.
     */
    func create(encodedProto: String, local: Bool, recordID: CKRecord.ID? = nil) -> Proto? {
        guard let proto = decodeProto(encodedProto: encodedProto) else { return nil }
        let document = Document(protoID: proto.id, proto: proto)
        if document.exists() {
            document.modify(new: proto, afterSave: {
                self.local = true
            })
        } else {
            document.createNew {
                self.local = true
            }
        }
        _fill(proto: proto, local: local, recordID: recordID)
        return proto
    }
    
    /**
        # Modify variables
        Function edit object variables.
     */
    func modifyVariables(new: DatabaseArchive) {
        _fill(da: new)
    }
    
    /**
        # Fill with data
        Function fill object variables with given protocol.
     */
    func fillWithData(proto: Proto, local: Bool, recordID: CKRecord.ID? = nil) -> String? {
        guard let encoded = try? JSONEncoder().encode(proto).base64EncodedString() else { printError(from: "fillWithData", message: "Cannot encode protocol[\(proto.id)]"); return nil}
        
        _fill(proto: proto, local: local, recordID: recordID == nil ? self.recordID : recordID)
        
        return encoded
    }
    
    /**
        # _Fill
        Function fill object.
     */
    private func _fill(da: DatabaseArchive) {
        self.client = da.client
        self.date = da.date
        self.local = da.local
        self.protoID = da.protoID
        self.construction = da.construction
        self.recordID = da.recordID
    }
    
    /**
        # _Fill
        Function fill object.
     */
    private func _fill(proto: Proto, local: Bool, recordID: CKRecord.ID?) {
        self.client = proto.client.name
        self.date = proto.creationDate
        self.local = local
        self.protoID = Int16(proto.id)
        self.construction = proto.construction.name
        self.recordID = recordID
    }
    
    /**
        # Decode proto
        Function decode given string as Protocol.
     */
    private func decodeProto(encodedProto: String) -> Proto? {
        guard let data = Data(base64Encoded: encodedProto) else {
            printError(from: "decodeProto", message: "Cannot convert encodedProto to data")
            return nil
        }
        guard let proto = try? JSONDecoder().decode(Proto.self, from: data) else {
            printError(from: "decodeProto", message: "Cannot decode encodedProto to Proto")
            return nil
        }
        return proto
    }

}

extension DatabaseArchive : Identifiable {

}
