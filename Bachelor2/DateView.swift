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
    private var locked: Binding<Bool>
    private var proto: Binding<Proto>
    
    init(proto: Binding<Proto>, locked: Binding<Bool>){
        self.proto = proto
        self.locked = locked
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
                if locked.wrappedValue == false {
                    proto.wrappedValue.creationDate = date
                    if proto.wrappedValue.creationDate != nil {
                        color = .green
                    }
                } else if proto.wrappedValue.creationDate != nil {
                    date = proto.wrappedValue.creationDate!
                }
                self.show.toggle()
            }){
                Text("OK").bold()
            }
                .padding(8)
            .background(locked.wrappedValue ? Color.gray : Color.blue)
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
