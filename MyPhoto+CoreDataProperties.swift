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
    
    private func getDir() -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docURL = documentsDirectory else { printError(from: "getDir", message: "Documents directory is nil"); return nil}
        let imagesPath = docURL.appendingPathComponent("Images")
        return imagesPath
    }
    
    func getPhotoPath() -> URL? {
        guard let dir = getDir() else { return nil }
        return dir.appendingPathComponent("\(protoID)_\(name).jpg")
    }
    
    func savePhotoToDisk(photo: UIImage?, protoID: Int, number: Int) {
        DispatchQueue.global().async {
            guard let dir = self.getDir() else { return }
            guard let photo = photo else { printError(from: "save photo", message: "Photo is nil"); return}
            guard let data = photo.jpegData(compressionQuality: 0.1) else { printError(from: "save photo", message: "Cannot convert photo into data"); return }
            self.name = Int16(number)
            self.protoID = Int16(protoID)
            let imagePath = dir.appendingPathComponent("\(protoID)_\(number).jpg")
            do {
                try data.write(to: imagePath)
            } catch {
                printError(from: "save photo", message: error.localizedDescription)
            }
            self.local = true
            print("Photo saved to disk")
        }
    }
    
//    func asynLoadPhotoFromDisk(completitionBlock: @escaping (Image) -> ()) {
//        guard local == true else { printError(from: "photo load", message: "Photo is not local"); return }
//        DispatchQueue.global().async() {
//            guard let dir = self.getDir() else { return }
//            let imagePath = dir.appendingPathComponent("\(self.protoID)_\(self.name).jpg")
//            guard let uiimage = UIImage(contentsOfFile: imagePath.path) else {
//                DispatchQueue.main.async {
//                    completitionBlock(Image(systemName: "photo"))
//                }
//                return
//            }
//            DispatchQueue.main.async {
//                completitionBlock(Image(uiImage: uiimage))
//                return
//            }
//        }
//    }
    
    func deleteFromDisk() {
        guard local == true else { print("Photo is not local"); return }
        DispatchQueue.global().async {
            guard let dir = self.getDir() else { return }
            let imagePath = dir.appendingPathComponent("\(self.protoID)_\(self.name).jpg")
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
