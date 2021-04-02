//
//  ProtocolListView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 20/03/2021.
//

import SwiftUI

struct ProtocolListView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) var DAs: FetchedResults<DatabaseArchive>
    @FetchRequest(entity: MyPhoto.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \MyPhoto.protoID , ascending: true)]) var photos: FetchedResults<MyPhoto>
    @FetchRequest(entity: OutputArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OutputArchive.protoID , ascending: true)]) var outputs: FetchedResults<OutputArchive>
    
    var body: some View {
        Form{
            ForEach(DAs, id:\.self){ item in
                NavigationLink(destination: ProtocolView(protoID: Int(item.protoID))
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
            Cloud.shared.insertFetchChangeIntoCoreData(moc: moc, allPhotos: photos, allDAs: DAs, allOutputs: outputs)
        }
    }
}
