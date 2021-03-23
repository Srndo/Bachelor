//
//  DatabaseArchive+CoreDataProperties.swift
//  Bachelor2
//
//  Created by Simon Sestak on 23/03/2021.
//
//

import Foundation
import CoreData


extension DatabaseArchive {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DatabaseArchive> {
        return NSFetchRequest<DatabaseArchive>(entityName: "DatabaseArchive")
    }

    @NSManaged public var encodedProto: String?
    @NSManaged public var client: String?
    @NSManaged public var date: Date?
    @NSManaged public var local: Bool
    @NSManaged public var protoID: Int16
    @NSManaged public var recordID: String?
    @NSManaged public var construction: String?

}

extension DatabaseArchive : Identifiable {

}
