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
    case kelvin = "K"
    case newton = "Nm"
    case kiloNewton = "kNm"
}

struct Company: Codable {
    var ico: Int = 0
    var dic: Int = 0
    var name: String = ""
    var address: String = ""
}

struct Construction: Codable {
    var name: String = ""
    var address: String = ""
    var section: String = ""
}

struct Device: Codable {
    var serialNumber: String = ""
    var name: String = ""
    var manufacturer: String = ""
}

struct MyMethod: Codable {
    var name: String = ""
    var about: String = "Popis metódy"
    var monitoredDimension: Dimensions = Dimensions.kiloPascal
    var requestedValue: Double = 0.0
}

struct Material: Codable {
    var material: String = ""
    var base: String = ""
}

struct Clima: Codable {
    var humAir: Double = 0.0
    var humCon: Double = 0.0
    var tempAir: Double = 0.0
    var tempCon: Double = 0.0
}

struct Proto: Codable {
    var id: Int
    var creationDate: Date?
    var info: String = ""
    var internalID: Int = 0
    var clima: Clima?
    var client: Company = Company()
    var construction: Construction = Construction()
    var device: Device = Device()
    var method: MyMethod = MyMethod()
    var material: Material = Material()
}
