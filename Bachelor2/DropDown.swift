//
//  DropDown.swift
//  Bachelor2
//
//  Created by Simon Sestak on 03/04/2021.
//

import SwiftUI

struct DropDown<Content: View>: View {
    let header: String
    @State var show: Bool = false
    let content: () -> Content
    
    init(header: String, show: Bool = false, content: @escaping () -> Content){
        self.header = header
        _show = State(initialValue: show)
        self.content = content
    }
    
    var body: some View {
        HStack{
            Text(header)
                .bold()
            Spacer()
            show ? Image(systemName: "chevron.down").foregroundColor(.gray) : Image(systemName: "chevron.right").foregroundColor(.gray)
        }
        .onTapGesture {
            show.toggle()
        }
        if show {
            self.content()
                .foregroundColor(.black)
        }
    }
}
