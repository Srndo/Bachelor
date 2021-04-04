//
//  ContentView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 18/03/2021.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) var moc
    @State private var selection: Int = 0
    @State private var show: Bool = false
    @State private var creator: Company = Company()
    @State private var ico: String = ""
    @State private var dic: String = ""
    var body: some View {
        TabView{
            NavigationView{
                ProtocolView()
                    .environment(\.managedObjectContext , moc)
            }
            .tabItem{
                VStack{
                    Text("Novy protokol")
                    Image(systemName: "doc.text")
                }
            }
            .tag(0)
            
            NavigationView{
                newList()
                    .environment(\.managedObjectContext , moc)
                    .navigationTitle("List protokolov")
            }
            .tabItem{
                VStack{
                    Text("List protokolov")
                    Image(systemName: "doc.on.doc")
                }
            }
            .tag(1)
        }
        .sheet(isPresented: $show) {
            CreatorView(show: $show)
        }
        .onAppear{
            if UserDefaults.standard.creator == nil {
                show.toggle()
            }
        }
        // if user wanna change "objednavatela" let some button in toolbar
        // image for logo in protocol
        // clima
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
