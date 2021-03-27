//
//  ProtocolListView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 20/03/2021.
//

import SwiftUI
import CloudKit

struct NewProtoListView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) private var DAs: FetchedResults<DatabaseArchive>
    @FetchRequest(entity: MyPhoto.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \MyPhoto.protoID , ascending: true)]) private var photos: FetchedResults<MyPhoto>
    
    var body: some View {
        Form{
            ForEach(DAs, id:\.self){ item in
                NavigationLink(destination: NewProtoView(protoID: Int(item.protoID), lastPhotoNumber: photos.last(where: { $0.protoID == item.protoID })?.name)
                                .environment(\.managedObjectContext , moc)){
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
            CloudHelper.shared.insertFetchChangeIntoCoreData(moc: moc, allPhotos: photos, allDAs: DAs)
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
            guard let recordID = remove.recordID else {
                printError(from: "remove protocol", message: "RecordID of protocol \(remove.protoID) is nil")
                return
            }
            // MARK: Cloud delete
            CloudHelper.shared.deleteFromCloud(recordID: recordID) { recordID in
                guard let recordID = recordID else { return }
                guard let removeCloud = DAs.first(where: { $0.recordID == recordID }) else {
                    printError(from: "remove cloud", message: "RecordID returned from cloud not exist in core data")
                    return
                }
                guard removeCloud == remove else {
                    printError(from: "remove cloud", message: "Marked protocol to remove and returned from cloud is not same")
                    return
                }
                removePhotos()
                removeDocument(protoID: Int(remove.protoID))
                moc.delete(remove)
                save(from: "remove cloud", message: "Cannot saved managed object context")
            }
        }
    }
    
    private func removeDocument(protoID: Int){
        let document = Document(protoID: protoID)
        
        if FileManager.default.fileExists(atPath: document.documentPath.path) {
            do {
                try document.delete()
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
