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
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) private var DAs: FetchedResults<DatabaseArchive>
    
    private var internalID: Int
    @State private var message: String = ""
    @State var proto: Proto
    
    @State private var ico: String = ""
    @State private var dic: String = ""
    @State private var reqVal: String = ""
    
    private let protoID: Int
    @State private var document: Document?
    
    init(protoID: Int? = nil){
        if let protoID = protoID  {
            self.protoID = protoID
        } else {
            self.protoID = -1
        }
        internalID = -1
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
                        if proto.id == -1 {
                            if let last = DAs.last {
                                proto.id = Int(last.protoID) + 1
                            } else {
                                proto.id = 1
                            }
                        }
                        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Documents").appendingPathComponent(String(proto.id) + String(".json"))
                        
                        // if was set as -1 (not to show on toolbar) set to 0 if new proto else set to old value
                        proto.internalID = proto.internalID == -1 ? 0 : proto.internalID
                        
                        if document == nil {
                            document = Document(protoID: proto.id, proto: proto)
                            guard let document = document else { printError(from: "protoView-document", message: "Document is nil"); return }
                            
                            document.save(to: path, for: .forCreating, completionHandler: { (res: Bool) in
                                print(res ? "Document saved " : "ERROR [UIDoc]: Cannot save document")
                                let newDA = DatabaseArchive(context: moc)
                                let encodedProto = newDA.fillWithData(proto: proto, local: true)
                                guard let encoded = encodedProto else { printError(from: "UIDoc", message: "Cannot save to cloud, encodedProto is nil"); return }
                                
                                Cloud.save(protoID: proto.id, encodedProto: encoded, completition: { result in
                                    switch result {
                                    case .failure(let err):
                                        printError(from: "cloud", message: "Protocol not saved into cloud")
                                        print(err)
                                        return
                                        
                                    case .success(let element):
                                        newDA.recordID = element.record.recordName
                                        do {
                                            try moc.save()
                                            print("Protocol saved on cloud")
                                        } catch {
                                            printError(from: "coredata", message: "RecordID not saved")
                                            print(error)
                                        }
                                    }
                                })
                                
                                do {
                                    try moc.save()
                                    proto = Proto(id: -1)
                                    self.message = "Protokol uložený"
                                } catch {
                                    self.message = "ERROR: Protokol sa nepodarilo uložiť"
                                    print(error)
                                }
                            })
                        } else {
                            document!.proto = proto
                            let DA = DAs.first(where: { $0.protoID == Int16(proto.id) })!
                            let _ = DA.fillWithData(proto: proto, local: true)
                            document!.updateChangeCount(.done)
                            
                            // MARK: TODO: Cloud modify
                            do {
                                try moc.save()
                                self.message = "Zmeny uložené"
                            } catch {
                                self.message = "ERROR: Zmeny sa nepodarilo uložiť"
                                print(error)
                            }
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
            guard protoID != -1 else { return }
            document = Document(protoID: protoID)
            guard let document = document else { printError(from: "protoView-document", message: "Document is nil"); return }
            
            document.open { res in
                if res {
                    print("Document with protocol \(protoID) opened.")
                    DispatchQueue.main.async {
                        guard let proto = document.proto else { printError(from: "protoView-document", message: "Document protocol is nil"); return }
                        self.proto = proto
                        self.ico = String(proto.client.ico)
                        self.dic = String(proto.client.dic)
                        self.reqVal = String(proto.method.requestedValue)
                    }
                } else {
                    printError(from: "protoView-document", message: "Document with protocol \(protoID) did not open")
                }
            }
        }
        .onDisappear{
            if let document = document {
                document.close{ res in
                    if res {
                        print("Document with protocol \(protoID) closed")
                    } else {
                        printError(from: "protoView-document", message: "Document with protocol \(protoID) did not closed")
                    }
                    
                }
            }
        }
    }
}

struct ProtocolView_Previews: PreviewProvider {
    static var previews: some View {
        ProtocolView()
    }
}
