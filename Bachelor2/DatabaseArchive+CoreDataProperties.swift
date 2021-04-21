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
        fill(proto: proto, local: local, recordID: recordID)
        return proto
    }
    
    func modifyVariables(new: DatabaseArchive) {
        fill(da: new)
    }
    
    func fillWithData(proto: Proto, local: Bool, recordID: CKRecord.ID? = nil) -> String? {
        guard let encoded = try? JSONEncoder().encode(proto).base64EncodedString() else { printError(from: "fillWithData", message: "Cannot encode protocol[\(proto.id)]"); return nil}
        
        fill(proto: proto, local: local, recordID: recordID)
        
        return encoded
    }
    
    private func fill(da: DatabaseArchive) {
        self.client = da.client
        self.date = da.date
        self.local = da.local
        self.protoID = da.protoID
        self.construction = da.construction
        self.recordID = da.recordID
    }
    
    private func fill(proto: Proto, local: Bool, recordID: CKRecord.ID?) {
        self.client = proto.client.name
        self.date = proto.creationDate
        self.local = local
        self.protoID = Int16(proto.id)
        self.construction = proto.construction.name
        self.recordID = recordID
    }
    
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
