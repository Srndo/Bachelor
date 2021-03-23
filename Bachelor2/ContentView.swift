//
//  ContentView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 18/03/2021.
//

import SwiftUI

struct ContentView: View {
    @State private var selection: Int = 0
    var body: some View {
        TabView{
            NavigationView{
                ProtocolView()
            }
            .tabItem{
                VStack{
                    Text("Novy protokol")
                    Image(systemName: "doc.text")
                }
            }
            .tag(0)
            
            NavigationView{
                ProtocolListView()
            }
            .tabItem{
                VStack{
                    Text("List protokolov")
                    Image(systemName: "doc.on.doc")
                }
            }
            .tag(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
