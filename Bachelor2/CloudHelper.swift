//
//  CloudClass.swift
//  Bachelor2
//
//  Created by Simon Sestak on 26/03/2021.
//

import CloudKit
import SwiftUI
import CoreData.NSManagedObjectContext

/**
 # Cloud
 Class contains functions to control cloud synchronizations with local database and files.
 */
class Cloud {
    struct RecordType {
        static let protocols = "Protocols"
        static let outputs = "Outputs"
        static let photos = "Photos"
    }
    
    static let shared = Cloud()
    lazy var container = CKContainer(identifier: "iCloud.cz.vutbr.fit.xsesta06")
    lazy var db = container.privateCloudDatabase
    lazy var zoneID = CKRecordZone(zoneName: "Bachelor").zoneID
    
    private var DAs: [DatabaseArchive] = []
    private var photos: [MyPhoto] = []
    private var outputs: [OutputArchive] = []
    private var newRecords: Bool {
        if DAs.isEmpty && photos.isEmpty && outputs.isEmpty {
            return false
        }
        return true
    }
    
    private var toDelete: [CKRecord.ID : CKRecord.RecordType] = [:]
    private var fetching: Bool = false
    private var inserting: Bool = false
    
    /**
     # Start zone
     Check if zone "Bachelor" was created.
     If not create zone.
     */
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
    
    /**
     # Print subscriptions
     Fetch all substriction from private database and print it.
     */
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
    
    /**
     # Start subscription
     Create substcription with subscriptionID = "updates"
     */
    func startSubscript() {
        let subscription = CKDatabaseSubscription(subscriptionID: "updates")
        let notifInfo = CKSubscription.NotificationInfo()
        notifInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notifInfo
        db.save(subscription) { _, err in
            if let err = err {
                printError(from: "start subscription", message: err.localizedDescription)
            }
        }
    }
    
    /**
     # Remove subscription
        Remove subscription with subscriptionID = "updates"
     */
    func removeSubscriptions() {
        db.delete(withSubscriptionID: "updates"){ string, err in
            if let string = string {
                print(string)
            }
            if let err = err {
                print(err)
            }
        }
    }
    
    // MARK: - Diff fetch
    /**
     # Diff Fetch
     Fetch only records that have changed since that anchor.
     Anchor is server token which is updated by every succesfull call of this function.
     */
    func doDiffFetch() {
        guard fetching == false else { return }
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
                self.fetching = false
                self.insertFetchChangeIntoCoreData()
                self.checkIfEveryThingIsOnCloud()
            }
        }
        
        db.add(operation)
    }
    
    // MARK: - Save to cloud functions
    /**
     # Save protocol to cloud
     Try to save new record into private database on cloud.
     - Parameter recordType: Record type of CKRecord to create
     - Parameter protoID: ID of protocol to save
     - Parameter encodedProto: Encoded protocol as String
     - Parameter completition: Return CKRecord if record was saved else nil
     */
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
                    guard let record = record else {
                        printError(from: "cloud save [protocol]", message: "Returned record is nil")
                        completition(nil)
                        return
                    }
                    print("Protocol saved on cloud")
                    completition(record.recordID)
                }
            }
        }
    }
    
    // MARK: saveToCloud(photo)
    /**
     # Save photo to cloud
     Try to save new record into private database on cloud.
     - Parameter recordType: Record type of CKRecord to create
     - Parameter photo: Instance of MyPhoto (NSManagedObject)
     - Parameter completition: Return CKRecord if record was saved else nil
     */
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
        record["local"] = photo.local as CKRecordValue
        record["diameter"] = photo.targetDiameter as CKRecordValue
        record["desc"] = photo.descriptionOfPlace as CKRecordValue
        
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
    
    // MARK: saveToCloud(output)
    /**
     # Save output to cloud
     Try to save new record into private database on cloud.
     - Parameter recordType: Record type of CKRecord to create
     - Parameter protoID: ID of protocol to save
     - Parameter internalID: internalID of protocol to save
     - Parameter pathTo: URL to ZIP file
     - Parameter completition: Return CKRecord if record was saved else nil
     */
    func saveToCloud(recordType: CKRecord.RecordType, protoID: Int, internalID: Int, zipURL: URL?, pdfURL: URL?, completition: @escaping (CKRecord.ID?) -> ()){
        guard recordType == RecordType.outputs else {
            printError(from: "save to cloud [zip]", message: "Record type is not correct")
            completition(nil)
            return
        }
        let recordID = CKRecord.ID(zoneID: zoneID)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["protoID"] = protoID as CKRecordValue
        record["internalID"] = internalID as CKRecordValue
        
        if let zipURL = zipURL {
            record["zip"] = CKAsset(fileURL: zipURL)
            record["zipLocal"] = true as CKRecordValue
        } else {
            record["zipLocal"] = false as CKRecordValue
        }
        
        
        if let pdfURL = pdfURL {
            record["pdf"] = CKAsset(fileURL: pdfURL)
            record["pdfLocal"] = true as CKRecordValue
        } else {
            record["pdfLocal"] = false as CKRecordValue
        }
        
        db.save(record) { record, err in
            DispatchQueue.main.async {
                if let err = err {
                    printError(from: "cloud save [output]", message: err.localizedDescription)
                    completition(nil)
                    return
                }
                
                guard let record = record else {
                    printError(from: "cloud save [output]", message: "Returned record from cloud is nil")
                    completition(nil)
                    return
                }
                
                print("Outputs saved on cloud")
                completition(record.recordID)
                return
            }
        }
    }
    
    // MARK: - Delete from cloud
    /**
     # Delete from cloud
     Try to remove record from private database on cloud.
     - Parameter recordID: Record ID of CKRecord to delete
     - Parameter completition: Return CKRecord if record was saved else nil
     */
    func deleteFromCloud(recordID: CKRecord.ID, completition: @escaping (CKRecord.ID?) -> ()) {
        db.delete(withRecordID: recordID) { recordID, err in
            DispatchQueue.main.async {
                if let err = err {
                    printError(from: "delete from cloud", message: err.localizedDescription)
                    completition(nil)
                    return
                }
                
                guard let recordID = recordID else {
                    completition(nil)
                    return
                }
                print("Record deleted from cloud")
                completition(recordID)
                return
            }
        }
    }
    
    // MARK: - Modify on cloud functions
    /**
     # Modify photo on cloud
     Try to modify record in private database on cloud.
     - Parameter photo: Instance of MyPhoto (NSManagedObject)
     */
    func modifyOnCloud(photo: MyPhoto) {
        guard let recordID = photo.recordID else {
            printError(from: "modify photo on cloud", message: "RecordID of photo \(photo.name) is nil")
            return
        }
        db.fetch(withRecordID: recordID) { record, err in
            if let err = err {
                printError(from: "modify photo on cloud", message: err.localizedDescription)
                return
            }
            guard let record = record else { return }
            record["value"] = photo.value as CKRecordValue
            record["name"] = photo.name as CKRecordValue
            record["local"] = photo.local as CKRecordValue
            record["diameter"] = photo.targetDiameter as CKRecordValue
            record["desc"] = photo.descriptionOfPlace as CKRecordValue
            
            self.db.save(record) { record, err in
                if let err = err {
                    printError(from: "modify photo on cloud", message: err.localizedDescription)
                    return
                }
                guard let _ = record else { return }
                print("Photo modified on cloud")
                return
            }
            
        }
    }
    
    // MARK: modifyOnCloud(proto)
    /**
     # Modify proto on cloud
     Try to modify record in private database on cloud.
     - Parameter recordID: Record ID of CKRecord to delete
     - Parameter proto: Instance of Proto (NSManagedObject)
     */
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
    
    // MARK: modifyOnCloud(output)
    /**
     # Modify output on cloud
     Try to modify record in private database on cloud.
     - Parameter output: Instance of OutputArchive (NSManagedObject)
     */
    func modifyOnCloud(output: OutputArchive) {
        guard let recordID = output.recordID else {
            printError(from: "modify output on cloud", message: "RecordID of output id:\(output.protoID), internal: \(output.internalID) is nil")
            return
        }
        db.fetch(withRecordID: recordID) { record, err in
            if let err = err {
                printError(from: "modify output on cloud", message: err.localizedDescription)
                return
            }
            guard let record = record else { return }
            record["zipLocal"] = output.zip as CKRecordValue
            record["pdfLocal"] = output.pdf as CKRecordValue
            
            self.db.save(record) { record, err in
                if let err = err {
                    printError(from: "modify output on cloud", message: err.localizedDescription)
                    return
                }
                guard let _ = record else { return }
                print("Output modified on cloud")
                return
            }
            
        }
    }
    
    // MARK: - Save record into class variables
    /**
     # Save records
     Will save new fetched records into class variables as instance of NSManagedObject (inserted into nil).
     This new objects can be inserted into local database and files by fucntion [insertFetchChangeIntoCoreData]
     - Parameter toSave: New CKRecords
     */
    private func saveRecords(toSave: [CKRecord]) {
        for record in toSave {
            switch record.recordType {
                case RecordType.photos:
                    savePhoto(record: record)
                    continue
            
                case RecordType.protocols:
                    saveProto(record: record)
                    continue
                    
                case RecordType.outputs:
                    saveOutput(record: record)
                    continue
                    
                default:
                    printError(from: "cloud save records", message: "Record type: \(record.recordType) is not handled")
            }
        }
    }
    
    // MARK: savePhoto()
    /**
     # Save photo
     Takes one CKRecord and if contains all needed informations create MyPhoto.
     And create (modify) local copy of that photo in .../Documents/{proto.id}/
     - Parameter record: record to save as MyPhoto
     */
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
        
        guard let local = record["local"] as? Bool else {
            printError(from: "cloud save photo", message: "Local of photo is nil")
            return
        }
        
        guard let diameter = record["diameter"] as? Double else {
            printError(from: "cloud save photo", message: "Diameter is nil")
            return
        }
        
        let photo = MyPhoto(entity: MyPhoto.entity(), insertInto: nil)
        photo.recordID = recordID
        
        if local {
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
            photo.savePhoto(toCloud: false, photo: data, protoID: protoID, name: name, value: value, diameter: diameter)
        } else {
            photo.name = Int16(name)
            photo.protoID = Int16(protoID)
            photo.value = value
            photo.local = false
            photo.targetDiameter = diameter
        }
        
        guard !photos.contains(where: { $0.protoID == photo.protoID && $0.name == photo.name }) else { return }
        photos.append(photo)
    }
    
    // MARK: saveProto()
    /**
     # Save proto
     Takes one CKRecord and if contains all needed informations create Proto.
     - Parameter record: record to save as MyPhoto
     */
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
        guard let _ = DA.create(encodedProto: encodedProto, local: false, recordID: recordID) else { return }
        
        guard !DAs.contains(where: { $0.protoID == DA.protoID }) else { return }
        DAs.append(DA)
        
    }
    
    // MARK: saveOutput()
    /**
     # Save output
     Takes one CKRecord and if contains all needed informations create Output.
     - Parameter record: record to save as OutputArchiver
     */
    private func saveOutput(record: CKRecord) {
        let recordID = record.recordID
        
        guard let protoID = record["protoID"] as? Int else {
            printError(from: "cloud save output", message: "ProtoID is nil")
            return
        }
        
        guard let internalID = record["internalID"] as? Int else {
            printError(from: "cloud save output", message: "internalID is nil")
            return
        }
        
        guard let zipLocal = record["zipLocal"] as? Bool, let pdfLocal = record["pdfLocal"] as? Bool else {
            printError(from: "cloud save output", message: "record do not contains informations if files is local")
            return
        }
        
        var zipExist: Bool = false
        var pdfExist: Bool = false
        if zipLocal {
            guard let zip = record["zip"] as? CKAsset, let zipURL = zip.fileURL, let zipData = try? Data(contentsOf: zipURL) else {
                printError(from: "cloud save output", message: "Cannot save zip file locally (zip missing or cannot be convert into data)")
                return
            }
            guard let zipSaveURL = Dirs.shared.getZipURL(protoID: protoID, internalID: internalID) else { return }
            zipExist = FileManager.default.createFile(atPath: zipSaveURL.path, contents: zipData, attributes: nil)
        }
        if pdfLocal {
            guard let pdf = record["pdf"] as? CKAsset, let pdfURL = pdf.fileURL, let pdfData = try? Data(contentsOf: pdfURL) else {
                printError(from: "cloud save output", message: "Cannot save pdf file locally (pdf missing or cannot be convert into data)")
                return
            }
            guard let pdfSaveURL = Dirs.shared.getPdfURL(protoID: protoID, internalID: internalID) else { return }
            pdfExist = FileManager.default.createFile(atPath: pdfSaveURL.path, contents: pdfData, attributes: nil)
        }
        
        let output = OutputArchive(entity: OutputArchive.entity(), insertInto: nil)
        output.fill(recordID: recordID, protoID: protoID, internalID: internalID, zipExist: zipExist, pdfExist: pdfExist)
        
        guard !outputs.contains(where: { $0.protoID == output.protoID && $0.internalID == output.internalID }) else { return }
        outputs.append(output)
    }
    
    
    private func checkIfEveryThingIsOnCloud() {
        DispatchQueue.main.async {
            let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            guard let allDAs = try? moc.fetch(DatabaseArchive.fetchRequest()) as? [DatabaseArchive] else { print("ooops"); return }
            guard let allPhotos = try? moc.fetch(MyPhoto.fetchRequest()) as? [MyPhoto] else  { print("ooops"); return }
            guard let allOutputs = try? moc.fetch(OutputArchive.fetchRequest()) as? [OutputArchive] else { print("ooops"); return }
            DispatchQueue.global().async {
                for da in allDAs {
                    if da.recordID == nil {
                        da.saveToCloud()
                    }
                }
                for photo in allPhotos {
                    if photo.recordID == nil {
                        self.saveToCloud(recordType: RecordType.photos, photo: photo){ record in
                            photo.recordID = record
                        }
                    }
                }
                for output in allOutputs {
                    if output.recordID == nil {
                        self.saveToCloud(recordType: RecordType.outputs, protoID: Int(output.protoID), internalID: Int(output.internalID), zipURL: output.getZipURL(), pdfURL: output.getPdfURL()){ record in
                            output.recordID = record
                        }
                    }
                }
                
                moc.trySave(savingFrom: "checkIfEveryThingIsOnCloud", errorFrom: "checkIfEveryThingIsOnCloud", error: "Cannot saved new changes")
            }
        }
    }
    
    // MARK: - Insert fetched changes into local core data
    /**
     # Insert fetch changes into local database
     If class variables contains NSMangedObjects is not empty.
     Create (modify, delete) this objects.
     */
    
    private func insertFetchChangeIntoCoreData() {
        DispatchQueue.main.async {
            guard self.fetching == false else { return }
            guard self.inserting == false else { return }
            self.inserting = true
            
            let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            guard let allDAs = try? moc.fetch(DatabaseArchive.fetchRequest()) as? [DatabaseArchive] else { print("ooops"); return }
            guard let allPhotos = try? moc.fetch(MyPhoto.fetchRequest()) as? [MyPhoto] else  { print("ooops"); return }
            guard let allOutputs = try? moc.fetch(OutputArchive.fetchRequest()) as? [OutputArchive] else { print("ooops"); return }
            
            if !self.toDelete.isEmpty {
                self.deleteRecords(moc: moc, allPhotos: allPhotos, allDAs: allDAs, allOutputs: allOutputs)
            }
            
            if self.newRecords {
                self.insertIntoMocPhotos(moc: moc, allPhotos: allPhotos)
                self.insertIntoMocDAs(moc: moc, allDAs: allDAs)
                self.insertIntoMocOutputs(moc: moc, allOutputs: allOutputs)
            }
            
            if !self.toDelete.isEmpty || self.newRecords {
                moc.trySave(savingFrom: "insertFetchChangeIntoCoreData", errorFrom: "insert fetch into DB", error: "Cannot save fetched changes")
                self.photos = []
                self.DAs = []
                self.outputs = []
                self.toDelete = [:]
            }
            self.inserting = false
        }
    }
    
    // MARK: deleteRecords()
    /**
     # Delete records
     Remove objects (saved in class variable) from local database and his files from sandbox.
     - Parameter moc: NSManagedObjectContext
     - Parameter allPhotos: Fetched results of already exists MyPhotos in local database
     - Parameter allDAs: Fetched results of already exists DatabaseArchive in local database
     */
    private func deleteRecords(moc: NSManagedObjectContext, allPhotos: [MyPhoto], allDAs: [DatabaseArchive], allOutputs: [OutputArchive]){
        for (recordID, recordType) in toDelete {
            if recordType == RecordType.protocols {
                guard let remove = allDAs.first(where: { $0.recordID == recordID }) else { continue }
                let document = Document(protoID: Int(remove.protoID))
                do {
                    try document.delete()
                    let removePhotos = allPhotos.filter{ $0.protoID == remove.protoID }
                    for photo in removePhotos {
                        photo.deleteFromDisk()
                        moc.delete(photo)
                    }
                    moc.delete(remove)
                } catch {
                    printError(from: "delete record [protocol]", message: error.localizedDescription)
                    print(error)
                    continue
                }
            } else if recordType == RecordType.photos {
                guard let remove = allPhotos.first(where: { $0.recordID == recordID }) else { continue }
                remove.deleteFromDisk()
                moc.delete(remove)
            } else if recordType == RecordType.outputs {
                guard let remove = allOutputs.first(where: { $0.recordID == recordID }) else { continue }
                if remove.deleteFromDisk() {
                    moc.delete(remove)
                }
            } else {
                printError(from: "delete record", message: "This record type \(recordType) is untreated")
            }
        }
    }
    
    // MARK: insertIntoMocPhotos()
    /**
     # Insert fetched photos into local database
     Insert new fetched photos changes into local database.
     - Parameter moc: NSManagedObjectContext into which is changes inserted
     - Parameter allPhotos: Fetched results of already exists MyPhotos in local database

     */
    private func insertIntoMocPhotos(moc: NSManagedObjectContext, allPhotos: [MyPhoto]) {
        for photo in photos {
            if let update = allPhotos.first(where: { $0.protoID == photo.protoID && $0.name == photo.name }) {
                // if local copy exist and on other device was local copy deleted
                if update.local == true && photo.local == false {
                    photo.deleteFromDisk()
                }
                update.local = photo.local
                update.value = photo.value
                update.recordID = photo.recordID
                
            }
            else if photo.managedObjectContext == nil {
                moc.insert(photo)
            }
        }
    }
    
    // MARK: insertIntoMocDAs()
    /**
     # Insert fetched protos into local database
     Insert new fetched protos changes into local database.
     - Parameter moc: NSManagedObjectContext into which is changes inserted
     - Parameter allDAs: Fetched results of already exists DatabaseArchive in local database
     */
    private func insertIntoMocDAs(moc: NSManagedObjectContext, allDAs: [DatabaseArchive]) {
        for da in DAs {
            if let update = allDAs.first(where: { $0.protoID == da.protoID }) {
                update.modifyVariables(new: da)
            } else if da.managedObjectContext == nil {
                moc.insert(da)
            }
        }
    }
    
    // MARK: insertIntoMocOutputs()
    /**
     # Insert fetched outputs into local database
     Insert new fetched outputs into local database.
     - Parameter moc: NSManagedObjectContext into which is changes inserted
     - Parameter allOutputs: Fetched results of already exists OutputArchive in local database
     */
    private func insertIntoMocOutputs(moc: NSManagedObjectContext, allOutputs: [OutputArchive]) {
        for output in outputs {
            if let update = allOutputs.first(where: {$0.protoID == output.protoID && $0.internalID == output.internalID}) {
                if update.zip == true && output.zip == false {
                    // remove local copy
                    _ = update.deleteZIPFromDisk()
                }
                if update.pdf == true && output.pdf == false {
                    // remove local copy
                    _ = update.deletePDFFromDisk()
                }
                update.pdf = output.pdf
                update.zip = output.zip
            } else {
                moc.insert(output)
            }
        }
    }
}
