//
//  ProtocolView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 20/03/2021.
//

import SwiftUI

struct ProtocolView: View {
    @Environment(\.managedObjectContext) var moc
    @Environment(\.colorScheme) var colorScheme
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) var allDA: FetchedResults<DatabaseArchive>
    @FetchRequest(entity: MyPhoto.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \MyPhoto.protoID , ascending: true)]) private var allPhotos: FetchedResults<MyPhoto>
    @FetchRequest(entity: OutputArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OutputArchive.protoID , ascending: true)]) var allOutputs: FetchedResults<OutputArchive>
    
    @State var internalID: Int = -1
    let protoID: Int
    
    @State var message: String = ""
    @State var proto: Proto
    @State var ico: String = ""
    @State var dic: String = ""
    @State var reqVal: String = ""
    @State var dimension: Dimensions?
    
    @State var document: Document?
    @State var photos: [MyPhoto] = []
    @State var lastPhotoNumber: Int = 1
    
    @State var locked: Bool = false
    @State private var creatingOutput: Bool = false
    
    @State private var activeSheet: ActiveSheet?
    @State private var creator: Company = Company()
    
    init(protoID: Int? = nil){
        if let protoID = protoID  {
            self.protoID = protoID
        } else {
            self.protoID = -1
        }
        
        _proto = State(initialValue: Proto(id: self.protoID))
        _dimension = State(initialValue: self.proto.device.dimension)
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
                    TextField("DIC", text: $dic).onChange(of: dic) { value in
                        if let dic = Int(value) {
                            proto.client.dic = dic
                        }
                    }
                }.disabled(locked)
            }.foregroundColor(proto.client.filled() ? .green : .red)

            
            DropDown(header: "Stavba"){
                Group{
                    TextField("*Názov", text: $proto.construction.name)
                    TextField("*Adresa", text: $proto.construction.address)
                    TextField("Sekcia", text: $proto.construction.section)
                }.disabled(locked)
            }.foregroundColor(proto.construction.filled() ? .green : .red)
            
            DropDown(header: "Zariadenie"){
                Group{
                    TextField("*Názov", text: $proto.device.name)
                    TextField("*Výrobca", text: $proto.device.manufacturer)
                    TextField("*Výrobné číslo", text: $proto.device.serialNumber)
                    HStack{
                        Picker("*Jednotky", selection: $dimension) {
                            ForEach(Dimensions.allCases, id:\.self) { dim in
                                Text(dim.rawValue).tag(dim as Dimensions?)
                            }.foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        }.foregroundColor(.gray)
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: dimension) { dim in
                            guard let dim = dim else { return }
                            proto.device.dimension = dim
                            print(proto.device.dimension.rawValue)
                        }
                        Spacer()
                        Text(proto.device.dimension.rawValue)
                    }
                }.disabled(locked)
            }.foregroundColor(proto.device.filled() ? .green : .red)
            
            DropDown(header: "Metóda"){
                Group{
                    TextField("*Druh skúšky", text: $proto.method.type)
                    TextField("*Názov metódy", text: $proto.method.name)
                    TextField("*Požadovaná minimálna hodnota", text: $reqVal).onChange(of: reqVal) { value in
                        if let reqVal = Double(value) {
                            proto.method.requestedValue = reqVal
                        }
                    }
                    TextField("*Sledovaná veličina", text: $proto.method.monitoredDimension)
                    TextEditor(text: $proto.method.about)
                        .foregroundColor(proto.method.about == "Popis metódy" ? .gray : .black)
                        .onTapGesture {
                            if proto.method.about == "Popis metódy" {
                                proto.method.about = ""
                            }
                        }
                        .onAppear{
                            if proto.method.about == "" {
                                proto.method.about = "Popis metódy"
                            }
                        }
                }.disabled(locked)
            }.foregroundColor(proto.method.filled() ? .green : .red)
            
            DropDown(header: "Materiál"){
                Group{
                    TextField("*Názov", text: $proto.material.material)
                    TextField("*Zhotoviteľ", text: $proto.material.manufacturer)
                    TextField("Podklad pod", text: $proto.material.base)
                }.disabled(locked)
            }.foregroundColor(proto.material.filled() ? .green : .red)
            
            DropDown(header: "Pracovný postup"){
                Group{
                    TextField("*Názov", text: $proto.workflow.name)
                }.disabled(locked)
            }.foregroundColor(proto.workflow.filled() ? .green : .red)
            
            DropDown(header: "Klimatické podmienky") {
                ClimaView(protoClima: $proto.clima, locked: $locked)
                    .disabled(locked)
            }.foregroundColor(proto.clima.filled() ? .green : .red)
            
            DropDown(header: "Popis") {
                Group {
                    TextEditor(text: $proto.info)
                        .foregroundColor(proto.info == "Popis / vyhodnotenie protokolu" ? .gray : .black)
                        .onTapGesture {
                        if proto.info == "Popis / vyhodnotenie protokolu" {
                            proto.info = ""
                        }
                    }
                }.disabled(locked)
            }.foregroundColor(!proto.info.isEmpty && proto.info != "Popis / vyhodnotenie protokolu" ? .green : .orange )

            Group { // struct allow only 10 views
                DateView(proto: $proto, locked: $locked)
                
                PhotoView(protoID: proto.id, internalID: proto.internalID, photos: $photos, lastPhotoIndex: $lastPhotoNumber, locked: $creatingOutput)
                    .environment(\.managedObjectContext , moc)
            }
            
                if protoID == -1 {
                    Section(header: Text(message).foregroundColor(message.contains("ERROR") ? .red : .green)) {
                        HStack {
                            Spacer()
                            Button("Vytvor testing"){
                                // for new proto create newID
                                if proto.id == -1 {
                                    proto.id = Int(allDA.last?.protoID ?? 0) + 1
                                }
                                // if was set as -1 (not to show on toolbar) set to 0 if new proto else set to old value
                                proto.internalID = proto.internalID == -1 ? 0 : proto.internalID
                                createNew()
                            }
                            .padding(8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            Spacer()
                        }
                    }
                } else {
                    Section(header: Text(message).foregroundColor(message.contains("ERROR") ? .red : .green)) {
                        HStack{
                            Button("Vytvor výstup") {
                                guard UserDefaults.standard.creator != nil else  {
                                    activeSheet = .first
                                    return
                                }
                                proto.internalID = proto.internalID == -1 ? 0 : proto.internalID
                                createOutput(creatingOutput: $creatingOutput)
                            }
                            .padding(8)
                            .background(proto.disabled() || creatingOutput || locked ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .buttonStyle(BorderlessButtonStyle())
                            .disabled(proto.disabled() || creatingOutput || locked)
                            Spacer()
                            Button("Uzavrieť protokol") {
                                locked = true
                                proto.locked = locked
                                
                                // do not need store archive photos locally anymore
                                removeLocalZIPsExpectLast()
                                removeLocalCopiesOfPhotos()
                            }
                            .padding(8)
                            .background(proto.disabled() || locked ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .buttonStyle(BorderlessButtonStyle())
                            .disabled(proto.disabled() || locked)
                        }
                    }
                    
                    Section(header: Text("Verzie")) {
                        VersionsView(protoID: protoID, versions: allOutputs.filter({ $0.protoID == protoID }))
                    }
                }
        }
        .navigationTitle(protoID != -1 ? "Protokol \(proto.id)" : "Nový protokol")
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing){
                internalID != -1 ? AnyView(Text("\(internalID)").foregroundColor(.gray)) : AnyView(EmptyView())
            }
        }
        .onAppear{
            if protoID > -1  && photos.isEmpty {
                photos = allPhotos.filter{ $0.protoID == Int16(proto.id) }
            }
            setAirClima()
            openDocument()
        }
        .onDisappear{
            self.message = ""
            modify(afterModified: closeDocument)
        }
        .sheet(item: $activeSheet){ id in
            if id == .first {
                CreatorView(activeSheet: $activeSheet)
            }
        }
    }
    
    private func printDB() {
        print("----------------")
        print("Photos: \(allPhotos.count)")
        print("DAs: \(allDA.count)")
        print("Outputs: \(allOutputs.count)")
        print("----------------")
    }
    
    private func setAirClima() {
        // set clima only in new protocol
        guard protoID == -1 else { return }
        WeatherService.shared.loadWeatherData() { weather in
            proto.clima.humAir = weather.humidity
            proto.clima.tempAir = weather.temperature
        }
    }
    private func clearDB() {
        for photo in allPhotos {
            moc.delete(photo)
        }
        for da in allDA {
            moc.delete(da)
        }
        for out in allOutputs {
            moc.delete(out)
        }
        moc.trySave(savingFrom: "clearDB", errorFrom: "clearDB", error: "oOoOoPs")
    }
    private func fillForTest(number: Int) {
        proto.client.name = "Firma \(number)"
        proto.client.address = "Adresa \(number)"
        proto.client.ico = number
        proto.client.dic = number
        proto.construction.address = "Adresa \(number)"
        proto.construction.name = "Stavba \(number)"
        proto.construction.section = "Sekcia \(number)"
        proto.creationDate = Date()
        proto.device.manufacturer = "Výrobca \(number)"
        proto.device.name = "Zariadenie \(number)"
        proto.device.serialNumber = "A\(number)B\(number*number)C"
        proto.material.material = "Material \(number)"
        proto.material.manufacturer = "Zhotoviteľ \(number)"
        proto.method.about = "Popis \(number)"
        proto.method.name = "Metóda \(number)"
        proto.method.requestedValue = Double(number)
        proto.method.type = "Odtrhová skúška"
        proto.method.monitoredDimension = "odtrhová sila / odtrhové napätie"
        proto.workflow.name = "PP-67"
        proto.clima.humCon = Double(number)
        proto.clima.tempCon = Double(number)
    }
}
