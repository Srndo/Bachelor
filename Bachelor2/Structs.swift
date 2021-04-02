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
}

struct MyMethod: Codable, Equatable {
    var name: String = ""
    var about: String = "Popis metódy"
    var monitoredDimension: Dimensions = Dimensions.kiloPascal
    var requestedValue: Double = 0.0
}

struct Material: Codable, Equatable {
    var material: String = ""
    var base: String = ""
}

struct Clima: Codable, Equatable {
    var humAir: Double = 0.0
    var humCon: Double = 0.0
    var tempAir: Double = 0.0
    var tempCon: Double = 0.0
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
            lhs.device == rhs.device &&
            lhs.method == rhs.method &&
            lhs.material == rhs.material &&
            lhs.lastPhotoIndex == rhs.lastPhotoIndex {
            return true
        }
        return false
    }
    
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
    
    var lastPhotoIndex: Int = 0
}


struct DropDown<Content: View>: View {
    let header: String
    @State var show: Bool = false
    let content: () -> Content
    
    init(header: String, show: Bool = false, content: @escaping () -> Content){
        self.header = header
        _show = State(initialValue: show)
        self.content = content
    }
    
    var body: some View {
        HStack{
            Text(header)
                .bold()
            Spacer()
            show ? Image(systemName: "chevron.down").foregroundColor(.gray) : Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .onTapGesture {
            show.toggle()
        }
        if show {
            self.content()
                .foregroundColor(.black)
        }
    }
}
