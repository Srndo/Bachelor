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

    @NSManaged public var local: Bool
    @NSManaged public var protoID: Int16
    @NSManaged public var name: Int16
    @NSManaged public var value: Double
    
    func getPhotoPath() -> URL? {
        guard let dir = Dirs.shared.getSpecificPhotoDir(protoID: Int(protoID)) else { return nil }
        return dir.appendingPathComponent("\(name).jpg")
    }
    
    func savePhotoToDisk(photo: UIImage?, protoID: Int, number: Int, value: Double = -1.0) {
        DispatchQueue.global().async {
            guard let dir = Dirs.shared.getSpecificPhotoDir(protoID: protoID) else { return }
            print(dir)
            guard let photo = photo else { printError(from: "save photo", message: "Photo is nil"); return}
            guard let data = photo.jpegData(compressionQuality: 0.1) else { printError(from: "save photo", message: "Cannot convert photo into data"); return }
            self.name = Int16(number)
            self.protoID = Int16(protoID)
            let imagePath = dir.appendingPathComponent("\(number).jpg")
            print(imagePath)
            do {
                try data.write(to: imagePath)
            } catch {
                printError(from: "save photo", message: error.localizedDescription)
            }
            self.local = true
            self.value = value
            print("Photo saved to disk")
        }
    }
    
    func deleteFromDisk() {
        guard local == true else { print("Photo is not local"); return }
        DispatchQueue.global().async {
            guard let dir = Dirs.shared.getSpecificPhotoDir(protoID: Int(self.protoID)) else { return }
            let imagePath = dir.appendingPathComponent("\(self.name).jpg")
            do {
                try FileManager.default.removeItem(at: imagePath)
            } catch {
                printError(from: "delete photo", message: error.localizedDescription)
            }
            self.local = false
            print("Photo removed from disk")
        }
    }

}

extension MyPhoto : Identifiable {

}
