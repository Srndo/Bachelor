//
//  NSAttributedCKRecordTransformer.swift
//  Bachelor2
//
//  Created by Simon Sestak on 21/04/2021.
//

import Foundation
import CloudKit.CKRecord

@objc(NSAttributedCKRecordTransformer)
class NSAttributedCKRecordTransformer: NSSecureUnarchiveFromDataTransformer {
    override class var allowedTopLevelClasses: [AnyClass] {
        return super.allowedTopLevelClasses + [CKRecord.ID.self]
    }
}
