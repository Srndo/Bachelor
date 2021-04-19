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
            Section(header: Text("Ovzdušie").foregroundColor(.gray)) {
                HStack{
                    TextField("Teplota", text: $tempAir)
                        .onChange(of: tempAir) { value in
                            guard let value = Double(value) else {
                                tempAir = ""
                                return
                            }
                            protoClima.tempAir = value
                        }
                    Spacer()
                    Text("°C")
                }
                HStack{
                    TextField("Vlhkosť", text: $humAir)
                        .onChange(of: humAir) { value in
                            guard let value = Double(value) else {
                                humAir = ""
                                return
                            }
                            protoClima.humAir = value
                        }
                    Spacer()
                    Text("%")
                }
            }
            Section(header: Text("Konštrukcia").foregroundColor(.gray)) {
                HStack{
                    TextField("Teplota", text: $tempCon)
                        .onChange(of: tempCon) { value in
                            guard let value = Double(value) else {
                                tempCon = ""
                                return
                            }
                            protoClima.tempCon = value
                        }
                    Spacer()
                    Text("°C")
                }
                HStack{
                    TextField("Vlhkosť", text: $humCon)
                        .onChange(of: humCon) { value in
                            guard let value = Double(value) else {
                                humCon = ""
                                return
                            }
                            protoClima.humCon = value
                        }
                    Spacer()
                    Text("%")
                }
            }.onAppear{
                if !protoClima.tempAir.isZero && !protoClima.humAir.isZero {
                    tempAir = String(protoClima.tempAir)
                    humAir = String(protoClima.humAir)
                }
                if !protoClima.humCon.isZero && !protoClima.tempCon.isZero {
                    humCon = String(protoClima.humCon)
                    tempCon = String(protoClima.tempCon)
                }
            }
        }
    }
}
