//
//  MyPhoto+CoreDataProperties.swift
//  Bachelor2
//
//  Created by Simon Sestak on 25/03/2021.
//
//

import SwiftUI
import CoreData


extension MyPhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyPhoto> {
        return NSFetchRequest<MyPhoto>(entityName: "MyPhoto")
    }

    @NSManaged public var descriptionOfPlace: String
    @NSManaged public var local: Bool
    @NSManaged public var name: Int16
    @NSManaged public var protoID: Int16
    @NSManaged public var recordID: CKRecord.ID?
    @NSManaged public var targetDiameter: Double
    @NSManaged public var value: Double
    
    func getPhotoPath() -> URL? {
        guard let dir = Dirs.shared.getSpecificPhotoDir(protoID: Int(protoID)) else { return nil }
        return dir.appendingPathComponent("\(name).jpg")
    }
    
    func savePhotoToDisk(photo: Data?, protoID: Int, name: Int, value: Double, diameter: Double){
        guard let dir = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return }
        guard let data = photo else { printError(from: "save photo", message: "Data is nil"); return }
        savePhoto(data: data, dir: dir, protoID: protoID, name: name, value: value, diameter: diameter)

    }
    
    func savePhotoToDisk(photo: UIImage?, protoID: Int, name: Int, value: Double, diameter: Double) {
            guard let dir = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return }
            guard let photo = photo else { printError(from: "save photo", message: "Photo is nil"); return}
            guard let data = photo.jpegData(compressionQuality: 0.1) else { printError(from: "save photo", message: "Cannot convert photo into data"); return }
        savePhoto(data: data, dir: dir, protoID: protoID ,name: name, value: value, diameter: diameter)
    }
    
    func deleteFromDisk() {
        DispatchQueue.global().async {
            guard let dir = Dirs.shared.getSpecificPhotoDir(protoID: Int(self.protoID)) else { return }
            let imagePath = dir.appendingPathComponent("\(self.name).jpg")
            if FileManager.default.fileExists(atPath: imagePath.path) {
                do {
                    try FileManager.default.removeItem(at: imagePath)
                } catch {
                    printError(from: "delete photo", message: error.localizedDescription)
                }
            }
            self.local = false
            print("Photo removed from disk")
        }
    }
    
    private func savePhoto(data: Data, dir: URL, protoID: Int, name: Int, value: Double, diameter: Double) {
        DispatchQueue.global().async {
            self.name = Int16(name)
            self.protoID = Int16(protoID)
            self.local = false
            self.value = value
            self.descriptionOfPlace = "-"
            self.targetDiameter = diameter
            let imagePath = dir.appendingPathComponent("\(name).jpg")
            do {
                try data.write(to: imagePath)
                self.local = true
                print("Photo saved to disk")
            } catch {
                printError(from: "save photo", message: error.localizedDescription)
            }
        }
    }

}

extension MyPhoto : Identifiable {

}
