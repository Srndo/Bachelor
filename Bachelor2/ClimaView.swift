//
//  ClimaView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 04/04/2021.
//

import SwiftUI

struct ClimaView: View {
    @Environment(\.openURL) var openURL
    @State private var humAir:String = ""
    @State private var humCon:String = ""
    @State private var tempAir:String = ""
    @State private var tempCon:String = ""
    @Binding var protoClima: Clima
    @Binding var locked: Bool
    
    var body: some View {
        Group {
            TextField("Vlhkosť ovzdušia [%]", text: $humAir)
                .onChange(of: humAir) { value in
                    guard let value = Double(value) else {
                        humAir = ""
                        return
                    }
                    protoClima.humAir = value
                }
            TextField("Teplota ovzdušia [°C]", text: $tempAir)
                .onChange(of: tempAir) { value in
                    guard let value = Double(value) else {
                        tempAir = ""
                        return
                    }
                    protoClima.tempAir = value
                }
            TextField("Vlhkosť konštrukcie [%]", text: $humCon)
                .onChange(of: humCon) { value in
                    guard let value = Double(value) else {
                        humCon = ""
                        return
                    }
                    protoClima.humCon = value
                }
            TextField("Teplota konštrukcie [°C]", text: $tempCon)
                .onChange(of: tempCon) { value in
                    guard let value = Double(value) else {
                        tempCon = ""
                        return
                    }
                    protoClima.tempCon = value
                }
            HStack{
                Spacer()
                Button("freemeteo.sk"){
                    guard let url = URL(string: "https://freemeteo.sk/") else { return }
                    openURL(url)
                }
                .padding(8)
                .background(locked ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                Spacer()
            }
        }.onAppear{
            humAir = String(protoClima.humAir)
            humCon = String(protoClima.humCon)
            tempAir = String(protoClima.tempAir)
            tempCon = String(protoClima.tempCon)
        }
    }
}
