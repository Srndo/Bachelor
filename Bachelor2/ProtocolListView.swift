//
//  ProtocolListView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 20/03/2021.
//

import SwiftUI

struct ProtocolListView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) private var DAs: FetchedResults<DatabaseArchive>
    
    var body: some View {
        Form{
            ForEach(DAs, id:\.self){ item in
                NavigationLink(destination: ProtocolView(protoID: Int(item.protoID))){
                    HStack{
                        VStack{
                            Text(item.client)
                            Text(item.construction)
                        }
                        Spacer()
                        Text("\(item.protoID)")
                    }
                }
            }
        }.onAppear{
            // MARK: Cloud fetch
            Cloud.fetch{ result in
                switch result {
                case .failure(let error):
                    printError(from: "cloud fetch", message: "Cannot fetched protocols")
                    print(error)
                    return
                        
                case .success(let element):
                    guard let encodedProto = element.encodedProto else { printError(from: "cloud fetch", message: "Encoded proto missing"); return }
                    
                    let document: Document
                    let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Documents")
                    
                    // if exist local copy of proto -> update proto
                    if let DA = DAs.first(where: { $0.recordID == element.record.recordName }){
                        guard let proto = DA.fillWithData(encodedProto: encodedProto, local: false) else { return }
                        let filePath = path.appendingPathComponent(String(proto.id) + String(".json"))
                        
                        // check if document with this proto exist
                        if FileManager.default.fileExists(atPath: filePath.path){
                            document = Document(protoID: proto.id)
                            document.proto = proto
                            document.updateChangeCount(.done) // MARK: TODO check if it is saving auto
                            
                            save(from: "cloud fetch", message: "Cannot save fetched item into coredata")
                            return
                        }
                    }
                    
                    // if fetched proto doesnt exist locally
                    let newDA = DatabaseArchive(context: moc)
                    guard let proto = newDA.fillWithData(encodedProto: encodedProto, local: false) else { return }
                    
                    document = Document(protoID: proto.id, proto: proto)
                    
                    document.save(to: path, for: .forCreating){ res in
                        if res {
                            newDA.local = true
                            print("Fetched document created")
                            save(from: "cloud fetch", message: "Cannot save fetched item into coredata")
                        } else {
                            printError(from: "cloud fetch", message: "Cannot create fetched document")
                        }
                    }
                    save(from: "cloud fetch", message: "Cannot save fetched item into coredata")
                    
                }
            
            }
        }
    }
    
    private func save(from: String, message: String) {
        do {
            try moc.save()
        } catch {
            printError(from: from, message: message)
            print(error)
            return
        }
    }
}

struct ProtocolList_Previews: PreviewProvider {
    static var previews: some View {
        ProtocolListView()
    }
}
