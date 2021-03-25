//
//  PhotoView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 25/03/2021.
//

import SwiftUI

struct PhotoView: View {
    @State private var show: Bool = false
    private var protoID: Int
    private var photoIndex: Int
    
    init(protoID: Int, photoIndex: Int){
        self.protoID = protoID
        self.photoIndex = photoIndex
    }
    
    var body: some View {
        ZStack{
            NavigationLink(destination: PhotosView()){
                EmptyView()
            }
            .hidden()
            .frame(width: 0)
            
            Button(action:{
                self.show.toggle()
            }){
                Text("Fotky")
                    .bold()
                    .foregroundColor(Color.red)
            }
        }
    }
}

struct PhotosView: View {
    @State private var actionShow: Bool = false
    @State private var showPicker: Bool = false
    @State private var source: UIImagePickerController.SourceType = .photoLibrary
    @State var photos: [MyPhoto] = []
    
    var body: some View {
        Form{
            HStack {
                Spacer()
                Button(action: {
                    self.actionShow.toggle()
                }){
                    Text("Pridaj fotku")
                }.padding(8)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
                Spacer()
            }
            .actionSheet(isPresented: $actionShow){
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    return ActionSheet(title: Text("Urob fotku alebo vyber z kniznice"), message: Text(""), buttons:
                        [.default(Text("Kniznica"), action: {
                            self.source = .photoLibrary
                            self.showPicker.toggle()
                        }),
                         .default(Text("Kamera"), action: {
                            self.source = .camera
                            self.showPicker.toggle()
                         }),
                        .cancel(Text("Zavri"))
                        ]
                    )
                } else {
                    return ActionSheet(title: Text("Vyber fotku z kniznice"), message: Text(""), buttons:
                        [.default(Text("Kniznica"), action: {
                            self.source = .photoLibrary
                            self.showPicker.toggle()
                        }),
                        .cancel(Text("Zavri"))
                        ]
                    )
                }
            }
            .sheet(isPresented: $showPicker){
                // MARK: TODO: ImagePicker
                // image picker needs to create MyPhoto
                // find the value in photo
                // call fce for saving photo into data
//                ImagePicker(model: model, isShow: $showPicker, source: source)
            }
            
            ForEach(photos, id:\.self) { photo in
                HStack{
                    ImageView(photo: photo)
                    Divider()
                    Text(String(photo.value))
                }
            }
        }
        .onDisappear{
            // MARK: TODO: Cloud save
            // on disappear save created photos on cloud
            // if photosIndex is >0 than
            // MARK: TODO: Cloud modify
        }
        .onAppear{
            // MARK: TODO: Cloud fetch
            // on appear fetch new photos
        }
    }
}
