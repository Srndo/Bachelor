//
//  OutputArchive+CoreDataProperties.swift
//  Bachelor2
//
//  Created by Simon Sestak on 02/04/2021.
//
//

import Foundation
import CoreData


extension OutputArchive {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OutputArchive> {
        return NSFetchRequest<OutputArchive>(entityName: "OutputArchive")
    }

    @NSManaged public var recordID: CKRecord.ID?
    @NSManaged public var zip: Bool
    @NSManaged public var pdf: Bool
    @NSManaged public var protoID: Int16
    @NSManaged public var internalID: Int16
    
    func fill(recordID: CKRecord.ID? = nil, protoID: Int, internalID: Int, zipExist: Bool, pdfExist: Bool){
        self.recordID = recordID
        self.protoID = Int16(protoID)
        self.internalID = Int16(internalID)
        self.zip = zipExist
        self.pdf = pdfExist
    }
    
    func deletePDFFromDisk() -> Bool {
        let ret = Dirs.shared.remove(at: Dirs.shared.getPdfURL(protoID: Int(protoID), internalID: Int(internalID)))
        if ret {
            pdf = false
        }
        return ret
    }
    
    func deleteZIPFromDisk() -> Bool {
        let ret = Dirs.shared.remove(at: Dirs.shared.getZipURL(protoID: Int(protoID), internalID: Int(internalID)))
        if ret {
            zip = false
        }
        return ret
    }
    
    func deleteFromDisk() -> Bool {
        return Dirs.shared.remove(at: Dirs.shared.getSpecificOutputDir(protoID: Int(protoID), internalID: Int(internalID)))
    }
}

extension OutputArchive : Identifiable {

}
