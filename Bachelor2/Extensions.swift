//
//  Extensions.swift
//  Bachelor2
//
//  Created by Simon Sestak on 23/03/2021.
//

import SwiftUI
import CloudKit
import CoreData.NSManagedObjectContext
import Zip

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
            self.photos = []
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
                    self.lastPhotoNumber = proto.lastPhotoIndex
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
        
        // MARK: TODO: wait until document saved
        // add closure and into this closure createProtoPDF, and Cloud.shared.saveToCloud(pdf) <--- [cloud pretaz fce, same params except last]
        modify() // save incremented proto.id
        
        guard let zipURL = createPhotosZIP(protoID: protoID) else { return }
        Cloud.shared.saveToCloud(recordType: Cloud.RecordType.outputs, protoID: proto.id, internalID: proto.internalID, pathTo: zipURL){ _ in}
        createProtoPDF(protoID: protoID)
        return
    }
    
    private func createProtoPDF(protoID: Int) {
        // MARK: TODO: createProtoPDF
        print("Warning: Create protocol PDF")
        return
            
//        guard let outputURL = Dirs.shared.getSpecificOutputDir(protoID: protoID) else { return }
        // create PDF here
    }
    
    private func createPhotosZIP(protoID: Int) -> URL? {
        guard let imagesURL = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return nil } // dir where photos is stored
        guard let names = Dirs.shared.getConentsOfDir(at: imagesURL) else { return nil } // photos urls
        guard let zipURL = Dirs.shared.getZipURL(protoID: protoID, internalID: internalID) else { return nil }

        do {
            try Zip.zipFiles(paths: names, zipFilePath: zipURL, password: nil, progress: { (progres) -> () in
                print(progres)
            })
        } catch {
            printError(from: "cretePhotosZIP", message: error.localizedDescription)
            return  nil
        }

        // MARK: Remove local photo
        for photo in self.photos {
            photo.deleteFromDisk()
            photo.local = false
            Cloud.shared.modifyOnCloud(photo: photo)
        }
        moc.trySave(errorFrom: "create ZIP from photos", error: "Cannot saved remove changes [photo.local -> false]")
        print("ZIP with photos of protocol \(self.proto.id) was created at path\n\(zipURL)")
        return zipURL
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
                removePhotos(protoID: Int(remove.protoID))
                removeDocument(protoID: Int(remove.protoID))
                moc.delete(remove)
                moc.trySave(errorFrom: "remove cloud", error: "Cannot saved managed object context")
                _ = Dirs.shared.removeDir(at: Dirs.shared.getSpecificPhotoDir(protoID: Int(remove.protoID)))
                _ = Dirs.shared.removeDir(at: Dirs.shared.getProtocolOutputDir(protoID: Int(remove.protoID)))
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
    
    private func removePhotos(protoID: Int){
        let removes = self.photos.filter{ $0.protoID == protoID }
        for remove in removes {
            remove.deleteFromDisk()
            if let recordID = remove.recordID {
                Cloud.shared.deleteFromCloud(recordID: recordID){ _ in}
            }
            moc.delete(remove)
        }
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


extension PhotosView {
    func actionSheet() -> ActionSheet {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            return ActionSheet(title: Text("Urob fotku alebo vyber z kniznice"), message: Text(""), buttons:
                [.default(Text("Kniznica"), action: {
                    self.source = .photoLibrary
                    self.showPicker.toggle()
                }),
                 .default(Text("Kamera"), action: {
                    self.source = .camera
                    self.showPicker.toggle()
                 }),
                .cancel(Text("Zavri"))
                ]
            )
        } else {
            return ActionSheet(title: Text("Vyber fotku z kniznice"), message: Text(""), buttons:
                [.default(Text("Kniznica"), action: {
                    self.source = .photoLibrary
                    self.showPicker.toggle()
                }),
                .cancel(Text("Zavri"))
                ]
            )
        }
    }
    
    func getZipPhotos(zipURL: URL) {
        guard let imagePath = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return }
        do {
            try Zip.unzipFile(zipURL, destination: imagePath, overwrite: true, password: nil)
            insertExtractedPhotosToCoreData(from: imagePath)
        } catch {
            printError(from: "getZipPhotos", message: error.localizedDescription)
            print(error)
            return
        }
    }
    
    private func insertExtractedPhotosToCoreData(from: URL){
        guard let paths = Dirs.shared.getConentsOfDir(at: from) else {
            printError(from: "extracted photos", message: "Directory is empty\nURL: \(from)")
            return
        }
        var names: [String] = []
        paths.forEach{ path in
            let name = path.deletingPathExtension().lastPathComponent
            names.append(name)
        }
        print(names)
        photos.forEach{ photo in
            if names.contains(String(photo.name)) {
                photo.local = true
            }
        }
        moc.trySave(errorFrom: "create photos from ZIP", error: "Cannot saved creating changes [photo.local -> true]")
    }
    
    func deletePhoto(at offsets: IndexSet) {
        for index in offsets {
            let remove = photos[index]
            guard let recordID = remove.recordID else {
                print("Warning [remove photo]: RecordID of photo \(remove.protoID) is nil")
                remove.deleteFromDisk()
                photos.remove(at: index)
                moc.delete(remove)
                moc.trySave(errorFrom: "remove cloud", error: "Cannot saved managed object context")
                return
            }
            Cloud.shared.deleteFromCloud(recordID: recordID) { recordID in
                guard let recordID = recordID else { return }
                guard let removeCloud = photos.first(where: { $0.recordID == recordID }) else {
                    printError(from: "remove photo cloud", message: "RecordID returned from cloud not exist in photos contained by proto")
                    return
                }
                guard removeCloud == remove else {
                    printError(from: "remove cloud", message: "Marked protocol to remove and returned from cloud is not same")
                    return
                }
                remove.deleteFromDisk()
                photos.remove(at: index)
                moc.delete(remove)
                moc.trySave(errorFrom: "remove cloud", error: "Cannot saved managed object context")
            }
        }
    }
}
