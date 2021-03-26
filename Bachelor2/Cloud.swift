//
//  Cloud.swift
//  Bachelor2
//
//  Created by Simon Sestak on 18/03/2021.
//

import CloudKit
import SwiftUI

struct CloudResultEncodedProto {
    var recordID: CKRecord.ID
    var encodedProto: String?
}

struct CloudResultPhoto {
    var recordID: CKRecord.ID
    var protoID: Int
    var value: Double
    var name: Int
}

struct CloudResultZip {
    var recordID: CKRecord.ID
    var zip: String
    var protoID: Int
}

struct Cloud {
    struct CloudElements {
        static let zone = CKRecordZone(zoneName: "Bachelor")
        static let container = CKContainer(identifier: "iCloud.cz.vutbr.fit.xsesta06")
    }
    
    struct RecordType {
        static let protocols = "Protocols"
        static let zip = "Outputs"
        static let photos = "Photos"
    }
    
    enum CloudKitHelperErrors: Error {
        case recordFailure
        case recordIDFailure
        case castFailure
        case cursorFailure
        case assetFailure
    }
    
    static func savePhoto(protoID: Int, value: Double, name: Int, path: URL, completition: @escaping (Result<CloudResultPhoto, Error>) -> ()) {
        let recordID = CKRecord.ID( zoneID: CloudElements.zone.zoneID)
        let itemRecord = CKRecord(recordType: RecordType.photos, recordID: recordID)
        itemRecord["protoID"] = protoID as CKRecordValue
        itemRecord["value"] = value as CKRecordValue
        itemRecord["name"] = name as CKRecordValue
        
        let asset = CKAsset(fileURL: path)
        itemRecord["photo"] = asset
        
        CloudElements.container.privateCloudDatabase.save(itemRecord) { record , err in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                
                guard let record = record else {
                    completition(.failure(CloudKitHelperErrors.recordFailure))
                    return
                }
                
                let recordID = record.recordID
                
                guard let protoID = record["protoID"] as? Int else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let value = record["value"] as? Double else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let _ = record["photo"] as? CKAsset else {
                    completition(.failure(CloudKitHelperErrors.assetFailure))
                    return
                }
                
                guard let name = record["name"] as? Int else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                let element = CloudResultPhoto(recordID: recordID, protoID: protoID, value: value, name: name)
                completition(.success(element))
            }
        }
        
    }
    
    // MARK: TODO: Fetch new photo (last modification )
    static func fetchPhoto(completition: @escaping (Result<CloudResultPhoto, Error>) -> ()) {
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        
        let querry = CKQuery(recordType: RecordType.photos, predicate: predicate)
        querry.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: querry)
        operation.desiredKeys = ["protoID", "value", "photo", "name"]
        operation.resultsLimit = 50
        
        operation.recordFetchedBlock = { record in
            DispatchQueue.main.async {
                
                let recordID = record.recordID
                
                guard let protoID = record["protoID"] as? Int else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let value = record["value"] as? Double else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let asset = record["photo"] as? CKAsset else {
                    completition(.failure(CloudKitHelperErrors.assetFailure))
                    return
                }
                
                guard let name = record["name"] as? Int else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let photoURL = asset.fileURL else {
                    completition(.failure(CloudKitHelperErrors.assetFailure))
                    return
                }
                
                guard let data = try? Data(contentsOf: photoURL) else {
                    completition(.failure(CloudKitHelperErrors.assetFailure))
                    return
                }
                
                DispatchQueue.global().async {
                    do {
                        guard let imagePath = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return }
                        try data.write(to: imagePath.appendingPathComponent(String(name)))
                    } catch {
                        printError(from: "fetch photo", message: error.localizedDescription)
                        return
                    }
                }
                
                let element = CloudResultPhoto(recordID: recordID, protoID: protoID, value: value, name: name)
                
                print("Photo fetched")
                completition(.success(element))
            }
        }
        
        operation.queryCompletionBlock = { (_, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
            }
        }
        CloudElements.container.privateCloudDatabase.add(operation)
    }
    
    // MARK: TODO
    static func saveZIP(protoID: Int, zip: String, completition: @escaping (Result<CloudResultZip, Error>) -> ()) {
        let recordID = CKRecord.ID( zoneID: CloudElements.zone.zoneID)
        let itemRecord = CKRecord(recordType: RecordType.zip, recordID: recordID)
        itemRecord["protoID"] = protoID as CKRecordValue
        itemRecord["zip"] = zip as CKRecordValue // check if as CKRecordValue
        
        CloudElements.container.privateCloudDatabase.save(itemRecord){ record, err in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                
                guard let record = record else {
                    completition(.failure(CloudKitHelperErrors.recordFailure))
                    return
                }
                
                let recordID = record.recordID
                
                guard let zip = record["zip"] as? String else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let protoID = record["protoID"] as? Int else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                print("Zip saved  on cloud")
                let result = CloudResultZip(recordID: recordID, zip: zip, protoID: protoID)
                completition(.success(result))
            }
        }
    }
    
    // MARK: TODO
    static func fetchZIP(completition: @escaping (Result<CloudResultZip, Error>) -> ()) {
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        
        let querry = CKQuery(recordType: RecordType.zip, predicate: predicate)
        querry.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: querry)
        operation.desiredKeys = ["protoID", "zip"]
        operation.resultsLimit = 50
        
        operation.recordFetchedBlock = { record in
            DispatchQueue.main.async {
                
                let recordID = record.recordID
                
                guard let zip = record["zip"] as? String else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                guard let protoID = record["protoID"] as? Int else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                let result = CloudResultZip(recordID: recordID, zip: zip, protoID: protoID)
                
                print("ZIP fetched")
                completition(.success(result))
            }
        }
        
        operation.queryCompletionBlock = { (_, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
            }
        }
        
        CloudElements.container.privateCloudDatabase.add(operation)
        
    }
    
    // MARK: TODO
    static func modifyZIP(zip: String, recordID: CKRecord.ID, completition: @escaping (Result<CloudResultZip, Error>) -> ()){
        CloudElements.container.privateCloudDatabase.fetch(withRecordID: recordID, completionHandler: { record, err in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                
                guard let record = record else { return }
                record["zip"] = zip as CKRecordValue
                
                CloudElements.container.privateCloudDatabase.save(record) { record, err in
                    DispatchQueue.main.async {
                        if let err = err {
                            completition(.failure(err))
                            return
                        }
                        
                        guard let record = record else { return }
                        let recordID = record.recordID
                        guard let zip = record["zip"] as? String else { return }
                        guard let protoID = record["recordID"] as? Int else { return }
                        
                        
                        let result = CloudResultZip(recordID: recordID, zip: zip, protoID: protoID)
                        
                        print("ZIP modified on cloud")
                        completition(.success(result))
                    }
                }
                
            }
        })
    }
    
    // before usage insert proto into coredata and set flag to local [true]
    // after save insert ckrecord to this "row" in coredata
    // every application launch check if ckrecord.modificationDate is older than one week
    //      if yes remove encoded proto from disk, set flag to remote [false]
    static func save(protoID: Int, encodedProto: String, completition: @escaping (Result<CloudResultEncodedProto, Error>) -> ()){
        let recordID = CKRecord.ID (zoneID: CloudElements.zone.zoneID)
        let itemRecord = CKRecord(recordType: RecordType.protocols, recordID: recordID)
        itemRecord["protoID"] = protoID as CKRecordValue
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
                
                guard let _ = record["protoID"] as? Int else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                let result = CloudResultEncodedProto(recordID: recordID, encodedProto: encodedProto)
                
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
                
                print("Record delete from cloud")
                completition(.success(recordID))
            }
        })
    }
    
    static func fetch(completition: @escaping (Result<CloudResultEncodedProto, Error>) -> ()) {
        let predicate = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        
        let querry = CKQuery(recordType: RecordType.protocols, predicate: predicate)
        querry.sortDescriptors = [sort]
        
        let operation = CKQueryOperation(query: querry)
        operation.desiredKeys = ["protoID", "encodedProto"]
        operation.resultsLimit = 50
        
        operation.recordFetchedBlock = { record in
            DispatchQueue.main.async {
                
                let recordID = record.recordID
                
                guard let encodedProto = record["encodedProto"] as? String else {
                    completition(.failure(CloudKitHelperErrors.castFailure))
                    return
                }
                
                let result = CloudResultEncodedProto(recordID: recordID, encodedProto: encodedProto)
                
                print("Protocol fetched")
                completition(.success(result))
            }
        }
        
        operation.queryCompletionBlock = { (_, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
            }
        }
        
        CloudElements.container.privateCloudDatabase.add(operation)
        
    }
    
    static func modify(item: Proto, recordID: CKRecord.ID, completition: @escaping (Result<CloudResultEncodedProto, Error>) -> ()){
        CloudElements.container.privateCloudDatabase.fetch(withRecordID: recordID, completionHandler: { record, err in
            DispatchQueue.main.async {
                if let err = err {
                    completition(.failure(err))
                    return
                }
                
                guard let record = record else { return }
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                
                guard let encodedProto = try? encoder.encode(item).base64EncodedString() else { printError(from: "cloud modify", message: "Cannot encoded proto \(item.id)"); return }
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
                        
                        
                        let result = CloudResultEncodedProto(recordID: recordID, encodedProto: encodedProto)
                        
                        print("Protocol modified on cloud")
                        completition(.success(result))
                    }
                }
                
            }
        })
    }
}
