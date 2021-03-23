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
            show ? Image(systemName: "chevron.right").foregroundColor(.gray) : Image(systemName: "chevron.down").foregroundColor(.gray)
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
    private let title: String
    private var internalID: Int
    @State var proto: Proto
    
    
    init(proto: Proto? = nil){
        if let proto = proto {
            title = String(proto.id)
            internalID = proto.internalID
            _proto = State(initialValue: proto)
        } else {
            title = "Nový protokol" // todo: set to ""
            internalID = -1
            _proto = State(initialValue: Proto(id: -1))
        }
    }
    
    var body: some View {
        Form {
            DropDown(header: "Klient"){
                Group{
                    TextField("*Názov", text: $proto.client.name)
                    TextField("*Adresa", text: $proto.client.address)
                    TextField("*ICO", text: $proto.client.ico.bound)
                    TextField("*DIC", text: $proto.client.dic.bound)
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
                    TextField("*Požadovaná minimálna hodnota", text: $proto.method.requestedValue.bound)
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
            
            HStack{
                Spacer()
                Button(proto.id == -1 ? "Vytvor" : "Uprav"){
                    if let last = DAs.last {
                        proto.id = Int(last.protoID)
                    } else {
                        proto.id = 1
                    }
                    
                    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Documents").appendingPathComponent(String(proto.id) + String(".json"))
                    let encodedProto: String
                    do {
                        encodedProto = try JSONEncoder().encode(proto).base64EncodedString()
                    } catch {
                        print(error)
                        return
                    }
                    let document = Document(fileURL: path, proto: proto)
                    
                    document.save(to: path, for: .forCreating, completionHandler: { (res: Bool) in
                        print(res ? "Document saved " : "ERROR [UIDoc]: Cannot save document")
                        // MARK: TODO: save to cloud
                        let newDA = DatabaseArchive(context: moc)
                        newDA.client = proto.client.name
                        newDA.construction = proto.construction.name
                        newDA.date = proto.creationDate
                        newDA.local = true
                        newDA.protoID = Int16(proto.id)
                        newDA.encodedProto = encodedProto
//                        newDA.recordID
                    })
                    proto = Proto(id: -1)
                }
                .disabled(proto.disabled())
                .padding(8)
                .background(proto.disabled() ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                Spacer()
            }
            
        }.toolbar{
            ToolbarItem(placement: .navigationBarLeading){
                Text("\(title)").foregroundColor(.gray)
            }
            ToolbarItem(placement: .navigationBarTrailing){
                internalID != -1 ? AnyView(Text("\(internalID)")) : AnyView(EmptyView())
            }
        }
    }
}

struct ProtocolView_Previews: PreviewProvider {
    static var previews: some View {
        ProtocolView()
    }
}
