//
//  CreatorView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 03/04/2021.
//

import SwiftUI

struct CreatorView: View {
    @State private var ico: String = ""
    @State private var placeholderIco: String = "*IČO firmy"
    @State private var creator: Company = Company()
    @State private var logo: UIImage? = nil
    @Binding var show: Bool
    @State private var showImagePicker: Bool = false
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Prosím vyplňte údaje o vašej firme.").bold()
                    Text("Údaje sa budú využívať pre tvorbu protokolov")
                }.font(.caption)
            }
            TextField("*Názov firmy", text: $creator.name)
            TextField("*Adresa firmy", text: $creator.address)
            TextField(placeholderIco, text: $ico).onChange(of: ico){ value in
                guard let ico = Int(value) else {
                    self.placeholderIco = "Chyba zadajte znova"
                    self.ico = ""
                    return
                }
                creator.ico = ico
            }
            Section {
                HStack{
                    Spacer()
                    Button("Vyrber logo firmy"){
                        showImagePicker.toggle()
                    }
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
                if logo != nil {
                    Image(uiImage: logo!).resizable().scaledToFit()
                }
            }
            Section {
                HStack{
                    Spacer()
                    Button("Ulož"){
                        show.toggle()
                    }
                    .padding(8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            LogoPicker(isShow: $showImagePicker, logo: $logo)
        }
        .onDisappear{
            if creator.filled() {
                UserDefaults.standard.creator = creator
            }
            UserDefaults.standard.logo = logo
        }
    }
}
