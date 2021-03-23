//
//  Cloud.swift
//  Bachelor2
//
//  Created by Simon Sestak on 18/03/2021.
//

import CloudKit
import SwiftUI

struct CloudResult {
    var record: CKRecord.ID
    var encodedProto: String?
}

struct Cloud {
    struct CloudElements {
        static let zone = CKRecordZone(zoneName: "Bachelor")
        static let container = CKContainer(identifier: "iCloud.cz.vutbr.fit.xsesta06")
    }
    
    struct RecordType {
        static let items = "Protocols"
    }
    
    enum CloudKitHelperErrors: Error {
        case recordFailure
        case recordIDFailure
        case castFailure
        case cursorFailure
        case assetFailure
    }
    
    // MARK: TODO:
    // before usage insert proto into coredata and set flag to local [true]
    // after save insert ckrecord to this "row" in coredata
    // every application launch check if ckrecord.modificationDate is older than one week
    //      if yes remove encoded proto from disk, set flag to remote [false]
    static func save(encodedProto: String, completition: @escaping (Result<CloudResult, Error>) -> ()){
        let recordID = CKRecord.ID (zoneID: CloudElements.zone.zoneID)
        let itemRecord = CKRecord(recordType: RecordType.items, recordID: recordID)
        itemRecord["encodedProto"] = encodedProto as CKRecordValue
        
        CloudElements.container.privateCloudDatabase.save(itemRecord, completionHandler: { (record , err) in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                
                guard let record = record else {
                    completition(.failure(CloudKitHelperErrors.recordFailure))
                    return
                }
                
                // insert into coreData
                let recordID = record.recordID
                
                guard let encodedProto = record["encodedProto"] as? String else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                let result = CloudResult(record: recordID, encodedProto: encodedProto)
                
                print("Protocol saved on cloud")
                
                completition(.success(result))
            }
        })
    }
    
    static func delete(recordID: CKRecord.ID, completition: @escaping (Result<CKRecord.ID, Error>) -> ()) {
        CloudElements.container.privateCloudDatabase.delete(withRecordID: recordID, completionHandler: { (recordID, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                
                guard let recordID = recordID else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                // remove from coreData
                print("Protocol delete from cloud")
                completition(.success(recordID))
            }
        })
    }
    
    static func fetch(protos: Protos, documentDir: URL, completition: @escaping (Result<CloudResult, Error>) -> ()) {
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        
        let querry = CKQuery(recordType: RecordType.items, predicate: predicate)
        querry.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: querry)
        operation.desiredKeys = ["encodedProto"]
        operation.resultsLimit = 50
        
        var fetched: [Proto] = []
        
        operation.recordFetchedBlock = { record in
            DispatchQueue.main.async {
                
                // todo recordID need to be inserted 
                let recordID = record.recordID
                
                guard let encodedProto = record["encodedProto"] as? String else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                 
                guard let data = Data(base64Encoded: encodedProto) else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let proto = try? JSONDecoder().decode(Proto.self, from: data) else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                fetched.append(proto)
                
                let result = CloudResult(record: recordID, encodedProto: encodedProto)
                print("Protocols fetched")
                completition(.success(result))
            }
        }
        
        operation.queryCompletionBlock = { (_, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                if fetched.count < protos.items.count {
                    protos.items = fetched
                }
            }
            
        }
        
        CloudElements.container.privateCloudDatabase.add(operation)
        
    }
    
    static func modify(item: Proto, recordID: CKRecord.ID, completition: @escaping (Result<CloudResult, Error>) -> ()){
        CloudElements.container.privateCloudDatabase.fetch(withRecordID: recordID, completionHandler: { record, err in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                
                guard let record = record else { return }
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                guard let encodedProto = try? encoder.encode(item).base64EncodedString() else { print("ERROR [cloud modify]: Cannot encoded proto \(item.id)"); return }
                record["encodedProto"] = encodedProto as CKRecordValue
                
                CloudElements.container.privateCloudDatabase.save(record) { record, err in
                    DispatchQueue.main.async {
                        if let err = err {
                            completition(.failure(err))
                            return
                        }
                        
                        guard let record = record else { return }
                        let recordID = record.recordID
                        guard let encodedProto = record["encodedProto"] as? String else { return }
//                        guard let data = Data(base64Encoded: encodedProto) else { return }
//                        guard let proto = try? JSONDecoder().decode(Proto.self, from: data) else { return }
                        
                        
                        let result = CloudResult(record: recordID, encodedProto: encodedProto)
                        print("Protocol modified")
                        completition(.success(result))
                    }
                }
                
            }
        })
    }
}
