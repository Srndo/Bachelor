//
//  FilterView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 02/04/2021.
//

import SwiftUI
import CoreData

struct Filtred<T: NSManagedObject, Content: View>: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(entity: DatabaseArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \DatabaseArchive.protoID , ascending: true)]) var DAs: FetchedResults<DatabaseArchive>
    @FetchRequest(entity: MyPhoto.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \MyPhoto.protoID , ascending: true)]) var photos: FetchedResults<MyPhoto>
    @FetchRequest(entity: OutputArchive.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \OutputArchive.protoID , ascending: true)]) var outputs: FetchedResults<OutputArchive>
    
    var fetchedRequest: FetchRequest<T>
    var reports: FetchedResults<T> {fetchedRequest.wrappedValue}
    let content: (T) -> Content
    
    var body: some View {
        ForEach(fetchedRequest.wrappedValue, id: \.self){ report in
            self.content(report)
        }.onDelete(perform: remove)
    }
    
    init(filterKey: String, filter:String?, content: @escaping (T) -> Content){
        if filter != "" {
            fetchedRequest = FetchRequest<T>(entity: T.entity(), sortDescriptors: [NSSortDescriptor(key: "protoID", ascending: true)], predicate: NSPredicate(format: "%K BEGINSWITH %@", filterKey, filter!))
        }
        else{
            fetchedRequest = FetchRequest<T>(entity: T.entity(), sortDescriptors: [NSSortDescriptor(key: "protoID", ascending: true)])
        }
        self.content = content
    }
}

struct setFilter: View {
    @Binding var filter: String
    @Binding var keyname: String
    
    var body: some View {
        Form{
            Section{
                Picker("", selection: $keyname){
                    Text("Klient").tag("client")
                    Text("Dátum").tag("date")
                    Text("Konštrukcia").tag("construction")
                    Text("Protokol ID").tag("protoID")
                }.pickerStyle(SegmentedPickerStyle())
            }
            Section{
                TextField("Filtruj podľa", text: $filter)
            }
        }
    }
}
