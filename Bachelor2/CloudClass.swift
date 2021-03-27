//
//  CloudClass.swift
//  Bachelor2
//
//  Created by Simon Sestak on 26/03/2021.
//

import CloudKit
import SwiftUI
import CoreData.NSManagedObjectContext

class CloudHelper {
    struct RecordType {
        static let protocols = "Protocols"
        static let zip = "Outputs"
        static let photos = "Photos"
    }
    
    static let shared = CloudHelper()
    lazy var container = CKContainer(identifier: "iCloud.cz.vutbr.fit.xsesta06")
    lazy var db = container.privateCloudDatabase
    lazy var zoneID = CKRecordZone(zoneName: "Bachelor").zoneID
    
    private var DAs: [DatabaseArchive] = []
    private var photos: [MyPhoto] = []
    private var newRecords: Bool {
        if DAs.isEmpty && photos.isEmpty {
            return false
        }
        return true
    }
    
    private var toDelete: [CKRecord.ID : CKRecord.RecordType] = [:]
    private var fetching: Bool = false
    
    
    func startZone() {
        let myRecordZone = CKRecordZone(zoneName: "Bachelor")
        let zoneSet: Bool = UserDefaults.standard.bool(forKey: "ZoneSet")
        
        if !zoneSet {
            db.save(myRecordZone){ _, err in
                if let err = err {
                    printError(from: "start zone", message: err.localizedDescription)
                    UserDefaults.standard.set(false, forKey: "ZoneSet")
                } else {
                    print("Zone created")
                    UserDefaults.standard.set(true, forKey: "ZoneSet")
                }
            }
        }
    }
    
    func printSubscriptions() {
        db.fetchAllSubscriptions { subscriptions, err in
            if let err = err {
                printError(from: "print subscript", message: err.localizedDescription)
                return
            }
            guard let subscriptions = subscriptions else {
                printError(from: "print subscript", message: "Subscriptions is nil")
                return
            }
            print("Subscriptions:")
            for subscription in subscriptions {
                print(subscription)
            }
        }

    }
    
    func startSubscript() {
        let subscription = CKDatabaseSubscription(subscriptionID: "updates")
        let notifInfo = CKSubscription.NotificationInfo()
        notifInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notifInfo
        print(subscription)
        db.save(subscription) { _, err in
            if let err = err {
                printError(from: "start subscription", message: err.localizedDescription)
            }
        }
    }
    
    func removeSubscriptions() {
        db.delete(withSubscriptionID: "updates"){ string, err in
            if let string = string {
                print(string)
            }
            if let err = err {
                print(err)
            }
        }
        
//        db.delete(withSubscriptionID: "com.apple.coredata.cloudkit.private.subscription"){ string, err in
//            if let string = string {
//                print(string)
//            }
//            if let err = err {
//                print(err)
//            }
//        }
    }
    
    func doDiffFetch() {
        fetching = true
        var toSave: [CKRecord] = []
        var optsDict: [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [:]
        let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        options.previousServerChangeToken = UserDefaults.standard.serverChangeToken
        optsDict[zoneID] = options
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID], configurationsByRecordZoneID: optsDict)
        
        operation.recordChangedBlock = { record in
            toSave.append(record)
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            self.toDelete[recordID] = recordType
        }
        
        operation.recordZoneFetchCompletionBlock = { zone, newServerToken, _, more, error in
            if let serverToken = newServerToken, error == nil  {
                UserDefaults.standard.serverChangeToken = serverToken
                self.saveRecords(toSave: toSave)
            }
            self.fetching = false
        }
        
        db.add(operation)
    }
    
    func saveToCloud(recordType: CKRecord.RecordType, protoID: Int, encodedProto: String, completition: @escaping (CKRecord.ID?) -> ()) {
        guard recordType == RecordType.protocols else {
            printError(from: "save to cloud [protocol]", message: "Record type is not correct")
            return
        }
        let recordID = CKRecord.ID(zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["protoID"] = protoID as CKRecordValue
        record["encodedProto"] = encodedProto as CKRecordValue
        
        db.save(record) { record, err in
            DispatchQueue.main.async {
                if let err = err {
                    printError(from: "cloud save [protocol]", message: err.localizedDescription)
                    completition(nil)
                } else {
                    print("Protcol saved on cloud")
                    guard let record = record else {
                        printError(from: "cloud save [protocol]", message: "Returned record is nil")
                        completition(nil)
                        return
                    }
                    completition(record.recordID)
                }
            }
        }
    }
    

    func saveToCloud(recordType: CKRecord.RecordType, photo: MyPhoto, completition: @escaping (CKRecord.ID?) -> ()){
        guard recordType == RecordType.photos else {
            printError(from: "save to cloud [photo]", message: "Record type is not correct")
            completition(nil)
            return
        }
        let recordID = CKRecord.ID(zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["protoID"] = photo.protoID as CKRecordValue
        record["value"] = photo.value as CKRecordValue
        record["name"] = photo.name as CKRecordValue
        
        guard let path = photo.getPhotoPath() else {
            printError(from: "save to cloud [photo]", message: "Photo path is nil")
            completition(nil)
            return
        }
        let asset = CKAsset(fileURL: path)
        record["photo"] = asset
        db.save(record) { record, err in
            DispatchQueue.main.async {
                if let err = err {
                    printError(from: "cloud save [photo]", message: err.localizedDescription)
                    completition(nil)
                    return
                }
                
                guard let record = record else {
                    printError(from: "cloud save [photo]", message: "Returned record from cloud is nil")
                    completition(nil)
                    return
                }
                
                print("Photo saved on cloud")
                completition(record.recordID)
                return
            }
        }
    }
    
    
    func deleteFromCloud(recordID: CKRecord.ID, completition: @escaping (CKRecord.ID?) -> ()) {
        db.delete(withRecordID: recordID) { recordID, err in
            DispatchQueue.main.async {
                if let err = err {
                    printError(from: "delete from cloud", message: err.localizedDescription)
                    completition(nil)
                    return
                }
                
                print("Record deleted from cloud")
                guard let recordID = recordID else {
                    completition(nil)
                    return
                }
                completition(recordID)
                return
            }
        }
    }
    

    func modifyOnCloud(recordID: CKRecord.ID, proto: Proto) {
        db.fetch(withRecordID: recordID) { record, err in
            if let err = err {
                printError(from: "modify protocol on cloud", message: err.localizedDescription)
                return
            }
            guard let record = record else { return }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            guard let encodedProto = try? encoder.encode(proto).base64EncodedString() else {
                printError(from: "modify protocol on cloud", message: "Cannot encoded proto \(proto.id)")
                return
            }
            record["encodedProto"] = encodedProto as CKRecordValue
            self.db.save(record) { record, err in
                if let err = err {
                    printError(from: "modify protocol on cloud", message: err.localizedDescription)
                    return
                }
                guard let _ = record else { return }
                print("Protocol modified on cloud")
                return
            }
            
        }
    }
    
    private func saveRecords(toSave: [CKRecord]) {
        for record in toSave {
            switch record.recordType {
                case RecordType.photos:
                    savePhoto(record: record)
                    continue
            
                case RecordType.protocols:
                    saveProto(record: record)
                    continue
                    
                case RecordType.zip:
                    saveZip(record: record)
                    continue
                    
                default:
                    printError(from: "cloud save records", message: "Record type: \(record.recordType) is not handled")
            }
        }
    }
    
    private func savePhoto(record: CKRecord) {
        let recordID = record.recordID
        guard let protoID = record["protoID"] as? Int else {
            printError(from: "cloud save photo", message: "ProtoID is nil")
            return
        }
        
        guard let value = record["value"] as? Double else {
            printError(from: "cloud save photo", message: "Value of photo is nil")
            return
        }
        
        guard let name = record["name"] as? Int else {
            printError(from: "cloud save photo", message: "Name of photo is nil")
            return
        }
        
        guard let asset = record["photo"] as? CKAsset else {
            printError(from: "cloud save photo", message: "Asset is missing")
            return
        }
        
        guard let photoURL = asset.fileURL else {
            printError(from: "cloud save photo", message: "Photo URL is nil")
            return
        }
        
        guard let data = try? Data(contentsOf: photoURL) else {
            printError(from: "cloud save photo", message: "Cannot create data from asset")
            return
        }
        
        let photo = MyPhoto(entity: MyPhoto.entity(), insertInto: nil)
        photo.recordID = recordID
        photo.savePhotoToDisk(photo: data, protoID: protoID, name: name, value: value)
        
        photos.append(photo)
        
    }
    
    private func saveProto(record: CKRecord) {
        let recordID = record.recordID
        guard let _ = record["protoID"] as? Int else {
            printError(from: "cloud save proto", message: "ProtoID is nil")
            return
        }
        guard let encodedProto = record["encodedProto"] as? String else {
            printError(from: "cloud save proto", message: "Encoded proto is nil")
            return
        }
        
        let DA = DatabaseArchive(entity: DatabaseArchive.entity(), insertInto: nil)
        guard let _ = DA.fillWithData(encodedProto: encodedProto, local: false, recordID: recordID) else { return }
        
        DAs.append(DA)
        
    }
    
    private func saveZip(record: CKRecord) {
        //MARK: TODO
    }
    
    func insertFetchChangeIntoCoreData(moc: NSManagedObjectContext, allPhotos: FetchedResults<MyPhoto>, allDAs: FetchedResults<DatabaseArchive>) {
        guard fetching == false else { return }
        
        if !toDelete.isEmpty {
            deleteRecords(moc: moc, allPhotos: allPhotos, allDAs: allDAs)
        }
        
        if newRecords {
            insertIntoMocPhotos(moc: moc, allPhotos: allPhotos)
            insertIntoMocDAs(moc: moc, allDAs: allDAs)
        }
        
        if !toDelete.isEmpty || newRecords {
            do {
                try moc.save()
                photos = []
                DAs = []
                toDelete = [:]
            } catch {
                printError(from: "insert fetch into DB", message: error.localizedDescription)
            }
        }
    }
    
    private func deleteRecords(moc: NSManagedObjectContext, allPhotos: FetchedResults<MyPhoto>, allDAs: FetchedResults<DatabaseArchive>){
        for (recordID, recordType) in toDelete {
            if recordType == RecordType.protocols {
                guard let remove = allDAs.first(where: { $0.recordID == recordID }) else { continue }
                let document = Document(protoID: Int(remove.protoID))
                do {
                    try document.delete()
                    moc.delete(remove)
                    // MARK: TODO remove all photos that contains remove.protoID
                } catch {
                    printError(from: "delete record [protocol]", message: error.localizedDescription)
                    continue
                }
            } else if recordType == RecordType.photos {
                guard let remove = allPhotos.first(where: { $0.recordID == recordID }) else { continue }
                remove.deleteFromDisk()
                moc.delete(remove)
            } else {
                printError(from: "delete record", message: "This record type \(recordType) is untreated")
            }
        }
    }
    
    private func insertIntoMocPhotos(moc: NSManagedObjectContext, allPhotos: FetchedResults<MyPhoto>) {
        for photo in photos {
            if let update = allPhotos.first(where: { $0.protoID == photo.protoID && $0.name == photo.name }) {
                update.local = photo.local
                update.value = photo.value
                update.recordID = photo.recordID
                
            }
            else if photo.managedObjectContext == nil {
                moc.insert(photo)
            }
        }
    }
    
    private func insertIntoMocDAs(moc: NSManagedObjectContext, allDAs: FetchedResults<DatabaseArchive>) {
        for da in DAs {
            if let update = allDAs.first(where: { $0.protoID == da.protoID }) {
                guard let proto = update.fillWithData(encodedProto: da.encodedProto, local: false, recordID: da.recordID) else { continue }
                let document = Document(protoID: proto.id)
                document.modify(new: proto)
                
            }
            else if da.managedObjectContext == nil {
                moc.insert(da)
                guard let proto = da.decodeProto() else { continue }
                let document = Document(protoID: proto.id, proto: proto)
                document.createNew(completition: nil)
            }
        }
    }
}
