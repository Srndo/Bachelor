//
//  newList.swift
//  Bachelor2
//
//  Created by Simon Sestak on 02/04/2021.
//

import SwiftUI

struct ProtocolList: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) var DAs: FetchedResults<DatabaseArchive>
    @FetchRequest(entity: MyPhoto.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \MyPhoto.protoID , ascending: true)]) var photos: FetchedResults<MyPhoto>
    @FetchRequest(entity: OutputArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OutputArchive.protoID , ascending: true)]) var outputs: FetchedResults<OutputArchive>
    
    @State var filter:String = ""
    @State var keyName:String = "client"
    @State var activeSheet: ActiveSheet?
    
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
                        Text("\(proto.protoID)" + showDate(date: proto.date))
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { id in
            switch id {
                case .first:
                    CreatorView(activeSheet: $activeSheet)
                case .second:
                    setFilter(filter: $filter, keyname: $keyName)
            }
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarTrailing){
                Button(action: {activeSheet = .first}){
                    UserDefaults.standard.creator != nil ?  Image(systemName: "bag.fill") : Image(systemName: "bag")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {activeSheet = .second}){
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
    func showDate(date: Date?) -> String {
        guard let date = date else { return ""}
        return ":" + date.showYear()
    }
}
