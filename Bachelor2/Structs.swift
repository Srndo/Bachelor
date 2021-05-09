//
//  Structs.swift
//  Bachelor2
//
//  Created by Simon Sestak on 18/03/2021.
//

import SwiftUI

enum Dimensions: String, Equatable, CaseIterable, Codable {
    case pascal = "Pa"
    case kiloPascal = "kPa"
    case megaPascal = "MPa"
    case kelvin = "K"
    case newton = "Nm"
    case kiloNewton = "kNm"
    case megaNewton = "MNm"
}

struct Company: Codable, Equatable {
    var ico: Int = 0
    var dic: Int = 0
    var name: String = ""
    var address: String = ""
}

struct Construction: Codable, Equatable {
    var name: String = ""
    var address: String = ""
    var section: String = ""
}

struct Device: Codable, Equatable {
    var serialNumber: String = ""
    var name: String = ""
    var manufacturer: String = ""
    var dimension: Dimensions = Dimensions.kiloPascal
}

struct MyMethod: Codable, Equatable {
    var type: String = ""
    var name: String = ""
    var about: String = "Popis metódy"
    var monitoredDimension: String = ""
    var requestedValue: Double = 0.0
}

struct Material: Codable, Equatable {
    var material: String = ""
    var base: String = ""
    var manufacturer: String = ""
}

struct Clima: Codable, Equatable {
    var humAir: Double = 0.0
    var humCon: Double = 0.0
    var tempAir: Double = 0.0
    var tempCon: Double = 0.0
}

struct Workflow: Codable, Equatable {
    var name: String = ""
}

struct Proto: Codable, Equatable {
    static func == (lhs: Proto, rhs: Proto) -> Bool {
        if lhs.id == rhs.id &&
            lhs.creationDate == rhs.creationDate &&
            lhs.info == rhs.info &&
            lhs.internalID == rhs.internalID &&
            lhs.clima == rhs.clima &&
            lhs.client == rhs.client &&
            lhs.construction == rhs.construction &&
            lhs.workflow == rhs.workflow &&
            lhs.device == rhs.device &&
            lhs.device.dimension == rhs.device.dimension && 
            lhs.method == rhs.method &&
            lhs.material == rhs.material &&
            lhs.lastPhotoIndex == rhs.lastPhotoIndex &&
            lhs.locked == rhs.locked {
            return true
        }
        return false
    }
    
    var id: Int
    var creationDate: Date?
    var info: String = "Popis / vyhodnotenie protokolu"
    var internalID: Int = 0
    var clima: Clima = Clima()
    var client: Company = Company()
    var construction: Construction = Construction()
    var device: Device = Device()
    var method: MyMethod = MyMethod()
    var material: Material = Material()
    var workflow: Workflow = Workflow()
    
    var lastPhotoIndex: Int = 1
    var locked: Bool = false
}

enum ActiveSheet: Identifiable {
    case first, second
    
    var id: Int {
        hashValue
    }
}
