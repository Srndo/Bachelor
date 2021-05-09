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
    @State private var activeSheet: ActiveSheet?
    
    var body: some View {
        TabView{
            NavigationView{
                ProtocolView()
                    .environment(\.managedObjectContext , moc)
            }
            .tabItem{
                VStack{
                    Text("Nový protokol")
                    Image(systemName: "doc.text")
                }
            }
            .tag(0)
            
            NavigationView{
                ProtocolList()
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
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $activeSheet) { id in
            if id == .first {
                CreatorView(activeSheet: $activeSheet)
            }
        }
        .onAppear{
            if UserDefaults.standard.creator == nil {
                activeSheet = .first
            }
        }
    }
}
