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
        if creationDate != nil && client.filled() && construction.filled() && device.filled() && method.filled() && material.filled() && workflow.filled() {
            return false
        }
        return true
    }
}

extension Clima {
    func filled() -> Bool {
        if (humCon <= 0.0 || humAir <= 0.0) || (tempAir == 0.0 && tempCon == 0.0) {
            return false
        }
        return true
    }
}

extension Workflow {
    func filled() -> Bool {
        return !name.isEmpty
    }
}

extension Material {
    func filled() -> Bool {
        return !(material.isEmpty || manufacturer.isEmpty)
    }
}

extension MyMethod {
    func filled() -> Bool {
        return !(name.isEmpty || type.isEmpty || monitoredDimension.isEmpty || requestedValue <= 0.0)
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
        return !(ico <= 0 || name.isEmpty || address.isEmpty)
    }
}

// MARK: - ProtocolView
extension ProtocolView {
    func createNew() {
        if proto.creationDate == nil { proto.creationDate = Date() }
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
            
            // prepare for creating new protocol
            self.proto = Proto(id: -1)
            self.ico = ""
            self.dic = ""
            self.reqVal = ""
            self.photos = []
            self.message = "Protokol uložený"
        }
    }
    
    func modify(afterModified: @escaping (() -> ())) {
        guard protoID != -1 else { return }
        guard let document = document else { printError(from: "modify", message: "Document is nil"); return }
        if lastPhotoNumber > proto.lastPhotoIndex { proto.lastPhotoIndex = lastPhotoNumber } // if photo was added
        guard document.proto != proto else { afterModified(); return } // if proto is not changed afterModified contains closeDocument
        guard let DA = allDA.first(where: { $0.protoID == Int16(proto.id) }) else { printError(from: "modify", message: "Protocol for modifying is not in database"); return }
        guard let recordID = DA.recordID else { printError(from: "modify", message: "Record.ID of protocol[\(proto.id)] is nil"); return }
        let _ = DA.fillWithData(proto: proto, local: true, recordID: recordID)
        document.modify(new: proto, afterSave: afterModified)
        
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
                    if lastPhotoNumber < proto.lastPhotoIndex {
                        self.lastPhotoNumber = proto.lastPhotoIndex
                    }
                    self.internalID = proto.internalID
                    self.locked = proto.locked
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
    
    func removeLocalZIPsExpectLast() {
        // get all outputs with proto.id
        let outputs = allOutputs.filter{ $0.protoID == proto.id }
        for output in outputs {
            guard output.internalID != proto.internalID else { continue } // do not delete last zip file
            _ = output.deleteZIPFromDisk()
            Cloud.shared.modifyOnCloud(output: output)
        }
    }
    
    func removeLocalCopiesOfPhotos() {
        // Ready for removing on create of output
        for photo in self.photos {
            photo.deleteFromDisk()
            photo.local = false
            Cloud.shared.modifyOnCloud(photo: photo)
        }
    }
    
    func createOutput(creatingOutput: Binding<Bool>) {
        // increment internalID because we creating new output
        self.proto.internalID = proto.internalID + 1
        // show this incrementedID in view
        self.internalID = proto.internalID
        
        // save incremented proto.id
        creatingOutput.wrappedValue = true
        modify(afterModified: {
            guard let zipURL = createPhotosZIP(protoID: proto.id) else { return }
            guard let pdfURL = createProtoPDF(proto: proto, photos: photos) else { return }
            // if cloud save successfull create output archive
            let outArch = OutputArchive(context: self.moc)
            // save outputs on cloud
            Cloud.shared.saveToCloud(recordType: Cloud.RecordType.outputs, protoID: proto.id, internalID: proto.internalID, zipURL: zipURL, pdfURL: pdfURL){ recordID in
                outArch.recordID = recordID
                moc.trySave(savingFrom: "createOutput", errorFrom: "create outputs", error: "Cannot saved new entity of output archive")
                creatingOutput.wrappedValue = false
            }
            outArch.fill(protoID: proto.id, internalID: proto.internalID, zipExist: true, pdfExist: true)
            moc.trySave(savingFrom: "createOutput", errorFrom: "create outputs", error: "Cannot saved new entity of output archive")
        })
        return
    }
    
    private func createProtoPDF(proto: Proto, photos: [MyPhoto]) -> URL? {
        let pdfCreator = PDF()
        let pdfData = pdfCreator.createPDF(uiimage: nil, proto: proto, photos: photos)
        guard let pdfURL = Dirs.shared.getPdfURL(protoID: proto.id, internalID: proto.internalID) else { return nil }
        FileManager.default.createFile(atPath: pdfURL.path, contents: pdfData, attributes: nil)
        return pdfURL
    }
    
    private func createPhotosZIP(protoID: Int) -> URL? {
        guard let imagesURL = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return nil } // dir where photos is stored
        guard let names = Dirs.shared.getConentsOfDir(at: imagesURL) else { return nil } // photos urls
        guard let zipURL = Dirs.shared.getZipURL(protoID: protoID, internalID: internalID) else { return nil } // dir where zip gonna be stored
        
        do {
            try Zip.zipFiles(paths: names, zipFilePath: zipURL, password: nil, progress: { (progres) -> () in
                print("Ziping: \(progres)%")
            })
        } catch {
            printError(from: "cretePhotosZIP", message: error.localizedDescription)
            return  nil
        }

        moc.trySave(savingFrom: "createPhotosZip", errorFrom: "create ZIP from photos", error: "Cannot saved remove changes [photo.local -> false]")
        print("ZIP with photos of protocol \(self.proto.id) was created.")
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

// MARK: - Filtred
extension Filtred {
    func remove(at offSets: IndexSet) {
        for index in offSets {
            let remove = DAs[index]
            guard let recordID = remove.recordID else {
                printError(from: "remove protocol", message: "RecordID of protocol \(remove.protoID) is nil")
                return
            }
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
                removeOutputs(protoID: remove.protoID)
                _ = Dirs.shared.remove(at: Dirs.shared.getSpecificPhotoDir(protoID: Int(remove.protoID)))
                moc.delete(remove)
                moc.trySave(savingFrom: "protoListRemove", errorFrom: "remove cloud", error: "Cannot saved managed object context")
            }
        }
    }
    
    private func removeOutputs(protoID: Int16){
        let outputs: [OutputArchive] = self.outputs.filter({ $0.protoID == protoID })
        for output in outputs {
            if let recordID = output.recordID {
                Cloud.shared.deleteFromCloud(recordID: recordID){ _ in
                    _ = output.deleteFromDisk()
                }
            } else {
                _ = output.deleteFromDisk()
            }
            moc.delete(output)
        }
        _ = Dirs.shared.remove(at: Dirs.shared.getProtocolOutputDir(protoID: Int(protoID)))
    }
    
    private func removeDocument(protoID: Int){
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

// MARK: - UserDefaults
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
    
    var creator: Company? {
        get {
            guard let data = self.value(forKey: "creator") as? Data else { return nil }
            guard let company = try? JSONDecoder().decode(Company.self, from: data) else { return nil }
            return company
        }
        
        set {
            if let company = newValue {
                guard let data = try? JSONEncoder().encode(company) else {
                    self.removeObject(forKey: "creator")
                    return
                }
                self.setValue(data, forKey: "creator")
            } else {
                self.removeObject(forKey: "creator")
            }
        }
    }
}

// MARK: - NSManagedObjectContext
extension NSManagedObjectContext {
    public func trySave(savingFrom: String, errorFrom: String, error message: String){
        print("Saving from: \(savingFrom)\n")
        do {
            try self.save()
        } catch {
            printError(from: errorFrom, message: message)
            print(error)
            return
        }
    }
}

// MARK: - PhotosView
extension PhotosView {
    func actionSheet() -> ActionSheet {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            return ActionSheet(title: Text("Vyfotiť fotku alebo vybrať z knižnice"), message: Text(""), buttons:
                [.default(Text("Knižnica"), action: {
                    self.source = .photoLibrary
                    self.showPicker.toggle()
                }),
                 .default(Text("Kamera"), action: {
                    self.source = .camera
                    self.showPicker.toggle()
                 }),
                .cancel(Text("Zavrieť"))
                ]
            )
        } else {
            return ActionSheet(title: Text("Vybrať fotku z knižnice"), message: Text(""), buttons:
                [.default(Text("Knižnica"), action: {
                    self.source = .photoLibrary
                    self.showPicker.toggle()
                }),
                .cancel(Text("Zavrieť"))
                ]
            )
        }
    }
    
    func getZipPhotos() {
        guard let zipURL = Dirs.shared.getZipURL(protoID: protoID, internalID: internalID) else { return }
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
                Cloud.shared.modifyOnCloud(photo: photo)
            }
        }
        moc.trySave(savingFrom: "insertExtractedPhotsToCoreData", errorFrom: "create photos from ZIP", error: "Cannot saved creating changes [photo.local -> true]")
    }
    
    func deletePhoto(at offsets: IndexSet) {
        guard locked != true else { return }
        for index in offsets {
            let remove = photos[index]
            guard let recordID = remove.recordID else {
                print("Warning [remove photo]: RecordID of photo \(remove.protoID) is nil")
                remove.deleteFromDisk()
                photos.remove(at: index)
                moc.delete(remove)
                moc.trySave(savingFrom: "deletePhoto", errorFrom: "remove cloud", error: "Cannot saved managed object context")
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
                moc.trySave(savingFrom: "deleteFromCloud", errorFrom: "remove cloud", error: "Cannot saved managed object context")
            }
        }
    }
}
