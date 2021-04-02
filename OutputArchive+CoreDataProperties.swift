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
    
    func fill(recordID: CKRecord.ID? = nil, protoID: Int, zipExist: Bool, pdfExist: Bool){
        self.recordID = recordID
        self.protoID = Int16(protoID)
        self.zip = zipExist
        self.pdf = pdfExist
    }
}

extension OutputArchive : Identifiable {

}
