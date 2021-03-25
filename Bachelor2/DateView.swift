//
//  DateView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 23/03/2021.
//

import SwiftUI

struct DateView: View {
    @State private var show: Bool = false
    @State var color: Color = .red
    @State var date: Date = Date()
    private var proto: Binding<Proto>
    
    init(proto: Binding<Proto>){
        self.proto = proto
    }
    
    var body: some View {
        Button(action: {
            self.show.toggle()
        }, label: {
            HStack{
                Text("Dátum").bold().foregroundColor(color)
                Spacer()
                Image(systemName: "calendar").foregroundColor(.black)
            }
        })
        .sheet(isPresented: $show){
            DatePicker("Dátum vytvorenia protokolu", selection: $date)
                .datePickerStyle(GraphicalDatePickerStyle())
            Button(action: {
                proto.wrappedValue.creationDate = date
                if proto.wrappedValue.creationDate != nil {
                    color = .green
                }
                self.show.toggle()
            }){
                Text("OK").bold()
            }
                .padding(8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .onChange(of: proto.wrappedValue.creationDate){ value in
            guard let date = value else {
                self.color = .red
                return
            }
            self.date = date
            self.color = .green
        }
    }
}
