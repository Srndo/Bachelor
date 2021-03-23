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
            Cloud.fetch{ result in
                switch result {
                case .failure(let error):
                    print("ERROR [cloud fetch]: Cannot fetched protocols")
                    print(error)
                    return
                        
                case .success(let element):
                    guard let encodedProto = element.encodedProto else { print("ERROR [cloud fetch]: Encoded proto missing"); return }
                    guard let data = Data(base64Encoded: encodedProto) else { print("ERROR [cloud fetch]: Cannot convert to data"); return }
                    guard let proto = try? JSONDecoder().decode(Proto.self, from: data) else { print("ERROR [cloud fetch]: Cannot create proto"); return }
                    let document: Document
                    if let DA = DAs.first(where: { $0.recordID == element.record.recordName }){
                        DA.encodedProto = encodedProto
                        try? moc.save()
                        // add fetched proto to UIdocument
                    } else {
                        let newDA = DatabaseArchive(context: moc)
                        // make func for filling
                        // create new uidoc
                    }
                    
                }
            
            }
        }
    }
}

struct ProtocolList_Previews: PreviewProvider {
    static var previews: some View {
        ProtocolListView()
    }
}
