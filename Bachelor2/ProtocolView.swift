//
//  ProtocolView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 20/03/2021.
//

import SwiftUI

struct ProtocolView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) var DAs: FetchedResults<DatabaseArchive>
    @FetchRequest(entity: MyPhoto.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \MyPhoto.protoID , ascending: true)]) private var allPhotos: FetchedResults<MyPhoto>
    
    @State var internalID: Int = -1
    let protoID: Int
    @State var message: String = ""
    @State var proto: Proto
    @State var ico: String = ""
    @State var dic: String = ""
    @State var reqVal: String = ""
    @State var document: Document?
    @State var photos: [MyPhoto] = []
    private var lastPhotoNumber: Int
    
    init(protoID: Int? = nil, lastPhotoNumber: Int16? = nil){
        if let protoID = protoID  {
            self.protoID = protoID
        } else {
            self.protoID = -1
        }
        if let idx = lastPhotoNumber {
            self.lastPhotoNumber = Int(idx)
        } else {
            self.lastPhotoNumber = 0
        }
        
        _proto = State(initialValue: Proto(id: self.protoID))
        document = nil
    }
    
    var body: some View {
        Form {
            DropDown(header: "Klient"){
                Group{
                    TextField("*Názov", text: $proto.client.name)
                    TextField("*Adresa", text: $proto.client.address)
                    TextField("*ICO", text: $ico).onChange(of: ico) { value in
                        if let ico = Int(value) {
                            proto.client.ico = ico
                        }
                    }
                    TextField("*DIC", text: $dic).onChange(of: dic) { value in
                        if let dic = Int(value) {
                            proto.client.dic = dic
                        }
                    }
                }
            }.foregroundColor(proto.client.filled() ? .green : .red)
            
            DropDown(header: "Stavba"){
                Group{
                    TextField("*Názov", text: $proto.construction.name)
                    TextField("*Adresa", text: $proto.construction.address)
                    TextField("Sekcia", text: $proto.construction.section)
                }
            }.foregroundColor(proto.construction.filled() ? .green : .red)
            
            DropDown(header: "Zariadenie"){
                Group{
                    TextField("*Názov", text: $proto.device.name)
                    TextField("*Výrobca", text: $proto.device.manufacturer)
                    TextField("*Výrobné číslo", text: $proto.device.serialNumber)
                }
            }.foregroundColor(proto.device.filled() ? .green : .red)
            
            DropDown(header: "Metóda"){
                Group{
                    TextField("*Názov", text: $proto.method.name)
                    TextField("*Požadovaná minimálna hodnota", text: $reqVal).onChange(of: reqVal) { value in
                        if let reqVal = Double(value) {
                            proto.method.requestedValue = reqVal
                        }
                    }
                    Picker("*Jednotky", selection: $proto.method.monitoredDimension) {
                        ForEach(Dimensions.allCases, id:\.self) { dim in
                            Text(dim.rawValue)
                        }.foregroundColor(.black)
                    }.foregroundColor(.gray)
                    TextEditor(text: $proto.method.about)
                        .foregroundColor(proto.method.about == "Popis metódy" ? .gray : .black)
                        .onTapGesture {
                            if proto.method.about == "Popis metódy" {
                                proto.method.about = ""
                            }
                        }
                }
            }.foregroundColor(proto.method.filled() ? .green : .red)
            
            DropDown(header: "Materiál"){
                Group{
                    TextField("*Názov", text: $proto.material.material)
                    TextField("Podklad pod", text: $proto.material.base)
                }
            }.foregroundColor(proto.material.filled() ? .green : .red)

            DateView(proto: $proto)
            
            PhotoView(protoID: proto.id, photoIndex: lastPhotoNumber, photos: photos)
            
                if protoID == -1 {
                    Section(header: Text(message).foregroundColor(message.contains("ERROR") ? .red : .green)) {
                        HStack {
                            Spacer()
                            Button("Vytvor"){
                                // if was set as -1 (not to show on toolbar) set to 0 if new proto else set to old value
                                proto.internalID = proto.internalID == -1 ? 0 : proto.internalID
                                createNew()
                                if !photos.isEmpty {
                                    // MARK: TODO: Cloud save zip
                                }
                            }
                            .disabled(proto.disabled())
                            .padding(8)
                            .background(proto.disabled() ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            Spacer()
                        }
                    }
                } else {
                    Section(header: Text(message).foregroundColor(message.contains("ERROR") ? .red : .green)) {
                        HStack{
                            Button("Uprav"){
                                // if was set as -1 (not to show on toolbar) set to 0 if new proto else set to old value
                                proto.internalID = proto.internalID == -1 ? 0 : proto.internalID
                                modify()
                                if !photos.isEmpty{
                                    if lastPhotoNumber >= 0 {
                                        // MARK: TODO: Cloud modify zip
                                    } else {
                                        // MARK: TODO: Cloud save zip
                                    }
                                }
                            }
                            .disabled(proto.disabled())
                            .padding(8)
                            .background(proto.disabled() ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .buttonStyle(BorderlessButtonStyle())
                            Spacer()
                            Button("Vytvor výstup") {
                                proto.internalID = proto.internalID == -1 ? 0 : proto.internalID
//                                createOutput(protoID: proto.id)
                            }
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    
                    Section(header: Text("Verzie")) {
//                        showVersions(protoID: protoID)
                    }
                }
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading){
                protoID != -1 ? AnyView(Text("\(protoID)").foregroundColor(.gray)) : AnyView(EmptyView())
            }
            ToolbarItem(placement: .navigationBarTrailing){
                internalID != -1 ? AnyView(Text("\(internalID)").foregroundColor(.gray)) : AnyView(EmptyView())
            }
        }
        .onAppear{
            // in start app was diff fetch on appear it chceck if fetch is still in progress if not
            // will insert every changes into database
            Cloud.shared.insertFetchChangeIntoCoreData(moc: moc, allPhotos: allPhotos, allDAs: DAs)
            if protoID == -1 {
                proto.id = Int(DAs.last?.protoID ?? 0) + 1
            }
            photos = allPhotos.filter{ $0.protoID == Int16(proto.id) }
            openDocument()
        }
        .onDisappear{
            closeDocument()
        }
    }
}
