//
//  OutputArchive+CoreDataProperties.swift
//  Bachelor2
//
//  Created by Simon Sestak on 02/04/2021.
//
//

import Foundation
import CoreData
import Zip

extension OutputArchive {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OutputArchive> {
        return NSFetchRequest<OutputArchive>(entityName: "OutputArchive")
    }

    @NSManaged public var recordID: CKRecord.ID?
    @NSManaged public var zip: Bool
    @NSManaged public var pdf: Bool
    @NSManaged public var protoID: Int16
    @NSManaged public var internalID: Int16
    
    /**
        # Get PDF URL
        Function return URL of PDF file for object.
     */
    func getPdfURL() -> URL? {
        guard pdf == true else { return nil }
        return Dirs.shared.getPdfURL(protoID: Int(protoID), internalID: Int(internalID))
    }
    
    /**
        # Get ZIP URL
        Function return URL of ZIP file for object.
     */
    func getZipURL() -> URL? {
        guard zip == true else { return nil }
        return Dirs.shared.getZipURL(protoID: Int(protoID), internalID: Int(internalID))
    }
    
    /**
        # Fill
        Function will fill the object with given data.
     */
    func fill(recordID: CKRecord.ID? = nil, protoID: Int, internalID: Int, zipExist: Bool = false, pdfExist: Bool = false){
        self.recordID = recordID
        self.protoID = Int16(protoID)
        self.internalID = Int16(internalID)
        self.zip = zipExist
        self.pdf = pdfExist
    }
    
    /**
        # Delete PDF URL
        Function remove PDF from application SandBox.
     */
    func deletePDFFromDisk() -> Bool {
        let ret = Dirs.shared.remove(at: Dirs.shared.getPdfURL(protoID: Int(protoID), internalID: Int(internalID)))
        if ret {
            pdf = false
        }
        return ret
    }
    
    /**
        # Delete ZIP URL
        Function remove ZIP from application SandBox.
     */
    func deleteZIPFromDisk() -> Bool {
        let ret = Dirs.shared.remove(at: Dirs.shared.getZipURL(protoID: Int(protoID), internalID: Int(internalID)))
        if ret {
            zip = false
        }
        return ret
    }
    
    /**
        # Delete remaing files
        Function remove all remaing files of object stored in application SandBox.
     */
    func deleteFromDisk() -> Bool {
        return Dirs.shared.remove(at: Dirs.shared.getSpecificOutputDir(protoID: Int(protoID), internalID: Int(internalID)))
    }
    
    /**
        # Create PDF
        Function create PDF containting protocol and store it in application SandBox.
     */
    func createProtoPDF(proto: Proto, photos: [MyPhoto]) -> URL? {
        let pdfCreator = PDF()
        let pdfData = pdfCreator.createPDF(proto: proto, photos: photos)
        guard let pdfURL = getPdfURL() else { return nil }
        FileManager.default.createFile(atPath: pdfURL.path, contents: pdfData, attributes: nil)
        self.pdf = true
        return pdfURL
    }
    
    /**
        # Create ZIP
        Function create ZIP containting photos of protocol and store ZIP in application SandBox.
     */
    func createPhotosZIP() -> URL? {
        guard let imagesURL = Dirs.shared.getSpecificPhotoDir(protoID: Int(protoID)) else { return nil } // dir where photos is stored
        guard let names = Dirs.shared.getConentsOfDir(at: imagesURL) else { return nil } // photos urls
        guard !names.isEmpty else { return nil } // if doesnt exist any photo not create zip
        guard let zipURL = getZipURL() else { return nil } // dir where zip gonna be stored
        
        do {
            try Zip.zipFiles(paths: names, zipFilePath: zipURL, password: nil, progress: { (progres) -> () in
                print("Ziping: \(progres)%")
            })
        } catch {
            printError(from: "cretePhotosZIP", message: error.localizedDescription)
            return  nil
        }

        self.zip = true
        print("ZIP with photos of protocol \(self.protoID) was created.")
        return zipURL
    }
}

extension OutputArchive : Identifiable {

}
