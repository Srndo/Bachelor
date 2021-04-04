//
//  newList.swift
//  Bachelor2
//
//  Created by Simon Sestak on 02/04/2021.
//

import SwiftUI

struct newList: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) var DAs: FetchedResults<DatabaseArchive>
    @FetchRequest(entity: MyPhoto.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \MyPhoto.protoID , ascending: true)]) var photos: FetchedResults<MyPhoto>
    @FetchRequest(entity: OutputArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OutputArchive.protoID , ascending: true)]) var outputs: FetchedResults<OutputArchive>
    
    @State var filter:String = ""
    @State var keyName:String = "client"
    @State private var show: Bool = false
    
    var body: some View {
        Form {
            Filtred(filterKey: keyName, filter: filter){ (proto: DatabaseArchive) in
                NavigationLink(destination: ProtocolView(protoID: Int(proto.protoID))
                                .environment(\.managedObjectContext , moc)){
                    HStack{
                        VStack{
                            Text(proto.client)
                            Text(proto.construction)
                        }
                        Spacer()
                        Text("\(proto.protoID)")
                    }
                }
            }
        }.onAppear{
//            Cloud.shared.insertFetchChangeIntoCoreData(moc: moc, allPhotos: photos, allDAs: DAs, allOutputs: outputs)
        }
        .sheet(isPresented: $show) {
            setFilter(filter: $filter, keyname: $keyName)
        }
        .toolbar{
            ToolbarItem{
                Button(action: {show.toggle()}){
                    Image(systemName: "magnifyingglass.circle")
                }
            }
        }
    }
}

struct newList_Previews: PreviewProvider {
    static var previews: some View {
        newList()
    }
}
