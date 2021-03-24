//
//  ProtocolListView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 20/03/2021.
//

import SwiftUI
import CloudKit

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
            }.onDelete(perform: remove)
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
                    
                    // if exist local copy of proto -> update proto
                    if let DA = DAs.first(where: { $0.recordID == element.record }){
                        guard DA.encodedProto != encodedProto else { return }
                        guard let proto = DA.fillWithData(encodedProto: encodedProto, local: false, recordID: element.record) else { return }
                        let document = Document(protoID: proto.id)
                        let path = document.documentPath
                        
                        // check if document with this proto exist
                        if FileManager.default.fileExists(atPath: path.path){
                            document.proto = proto
                            document.updateChangeCount(.done) // MARK: TODO check if it is saving auto
                            document.save(to: path, for: .forOverwriting){ res in
                                if res == true {
                                    print("Document with protocol \(proto.id) overwrited")
                                } else {
                                    printError(from: "cloud fetch", message: "Document with protocol \(proto.id) did not overwrited")
                                }
                            }
                            save(from: "cloud fetch", message: "Cannot save fetched item into coredata")
                            return
                        }
                    }
                    
                    // if fetched proto doesnt exist locally
                    let newDA = DatabaseArchive(context: moc)
                    guard let proto = newDA.fillWithData(encodedProto: encodedProto, local: false, recordID: element.record) else { return }
                    
                    let document = Document(protoID: proto.id, proto: proto)
                    let path = document.documentPath
                    
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
    
    private func remove(at offSets: IndexSet) {
        for index in offSets {
            let remove = DAs[index]
            guard let recordID = remove.recordID else { printError(from: "remove", message: "RecordID of protocol \(remove.protoID) is nil"); return }
            // MARK: Cloud delete
            Cloud.delete(recordID: recordID){ res in
                switch res {
                case .failure(let err):
                    print(err)
                    return
                    
                case .success(let recordID):
                    let recordName = recordID
                    let removeCloud = DAs.first(where: { $0.recordID == recordName })
                    guard removeCloud != nil else { printError(from: "remove cloud", message: "RecordID returned from cloud not exist in core data"); return }
                    guard removeCloud! == remove else { printError(from: "remove cloud", message: "Marked protocol to remove and returned from cloud is not same"); return }
                    removePhotos()
                    removeDocument(protoID: Int(remove.protoID))
                    moc.delete(remove)
                    save(from: "remove cloud", message: "Cannot saved managed object context")
                }
            }
        }
    }
    
    private func removeDocument(protoID: Int){
        let document = Document(protoID: protoID)
        let path = document.documentPath
        
        if FileManager.default.fileExists(atPath: path.path) {
            do {
                try FileManager.default.removeItem(at: path)
                print("Document removed from local storage")
            } catch {
                printError(from: "remove document", message: "Cannot remove document for protocol[\(protoID)]")
                print(error)
            }
        }
    }
    
    private func removePhotos(){
        // MARK: TODO
        print("Warning: Not removing photos")
    }
}

struct ProtocolList_Previews: PreviewProvider {
    static var previews: some View {
        ProtocolListView()
    }
}
