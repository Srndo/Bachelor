//
//  ProtocolView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 20/03/2021.
//

import SwiftUI

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

struct ProtocolView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) var DAs: FetchedResults<DatabaseArchive>
    
    @State var modifying: Bool = false
    @State var internalID: Int = -1
    let protoID: Int
    
    @State var message: String = ""
    @State var proto: Proto
    
    @State var ico: String = ""
    @State var dic: String = ""
    @State var reqVal: String = ""
    
    @State var document: Document?
    
    init(protoID: Int? = nil){
        if let protoID = protoID  {
            self.protoID = protoID
        } else {
            self.protoID = -1
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
            
            Section(header: Text(message).foregroundColor(message.contains("ERROR") ? .red : .green)){
                HStack{
                    Spacer()
                    Button(proto.id == -1 ? "Vytvor" : "Uprav"){
                        // if protoID was set as -1 (new protocol) find last protoID in "DA" and increment (if empty 0 + 1 -> first proto) else set to old value
                        proto.id = proto.id == -1 ? Int(DAs.last?.protoID ?? 0) + 1 : proto.id
                        
                        // if was set as -1 (not to show on toolbar) set to 0 if new proto else set to old value
                        proto.internalID = proto.internalID == -1 ? 0 : proto.internalID
                        
                        if document == nil {
                            createNew()
                        } else {
                            modify()
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
            print("DAs.count:", DAs.count)
//            DAs.forEach{ da in
//                
//            }
            openDocument()
        }
        .onDisappear{
            closeDocument()
        }
    }
}

struct ProtocolView_Previews: PreviewProvider {
    static var previews: some View {
        ProtocolView()
    }
}
