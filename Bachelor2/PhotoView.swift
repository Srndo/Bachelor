//
//  PhotoView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 25/03/2021.
//

import SwiftUI
import Zip

struct PhotoView: View {
    @Environment(\.managedObjectContext) var moc
    
    @State private var show: Bool = false
    @State private var photos: [MyPhoto]
    var lastPhotoIndex: Binding<Int>
    private var protoID: Int
    private var internalID: Int
    
    
    init(protoID: Int, internalID: Int, photos: [MyPhoto], lastPhotoIndex: Binding<Int>){
        self.protoID = protoID
        self.internalID = internalID
        self.lastPhotoIndex = lastPhotoIndex
        _photos = State(initialValue: photos)
    }
    
    var body: some View {
        ZStack{
            NavigationLink(destination: PhotosView(photos: $photos, lastPhotoIndex: lastPhotoIndex, protoID: protoID, internalID: internalID)
                            .environment(\.managedObjectContext , moc)){
                EmptyView()
            }
            .hidden()
            .frame(width: 0)
            
            Button(action:{
                self.show.toggle()
            }){
                Text("Fotky")
                    .bold()
                    .foregroundColor(photos.isEmpty ? Color.red : Color.green)
            }
        }
    }
}

struct PhotosView: View {
    @Environment(\.managedObjectContext) var moc
    
    @State private var actionShow: Bool = false
    @State var showPicker: Bool = false
    @State var source: UIImagePickerController.SourceType = .photoLibrary
    
    @Binding var photos: [MyPhoto]
    // MARK: TODO: test lastPhotoIndex and for cloud too
    @Binding var lastPhotoIndex: Int
    @State var protoID: Int
    @State var internalID: Int
    @State private var showAllert: Bool = false
    @State private var edit: Bool = false
    @State private var newValue: String = "-1.0"
    @State private var editingPhoto: MyPhoto?
    @State private var placeholder: String = "Zadajte hodnotu"
    
    var body: some View {
        Form{
            Section{
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
                    actionSheet()
                }
                .sheet(isPresented: $showPicker){
                    ImagePicker(isShow: $showPicker, photos: $photos, lastPhotoIndex: $lastPhotoIndex, protoID: protoID, source: source)
                }
            }
            
            Section(header: VStack{Text("Pre zmenu hodnoty podrž prst na hodnote.");Text("Pre stiahnutie nenačítanej fotky podrdž prst na fotke.")}){
                ForEach(photos, id:\.self) { photo in
                    HStack{
                        ImageView(photo: photo).onLongPressGesture {
                            if !photo.local {
                                Cloud.shared.downloadPhoto(photo: photo)
                                // MARK: TODO: reload
                            }
                        }
                        Divider()
                        Text(String(photo.value)).onLongPressGesture {
                            self.edit.toggle()
                            newValue = String(photo.value)
                            editingPhoto = photo
                        }
                    }
                }.onDelete(perform: deletePhoto)
            }
        }
        .sheet(isPresented: $edit) {
            Form{
                Section{
                    HStack{
                        TextField(placeholder, text: $newValue)
                            .onChange(of: newValue, perform: { _ in
                                guard let value = Double(newValue) else { return }
                                if value < 0.0 {
                                    placeholder = "Prosim zadajte znova"
                                    newValue = ""
                                }
                            })
                        Button("Ulož"){
                            guard let photo = editingPhoto else { return }
                            guard let value = Double(newValue) else { return }
                            photo.value = value
                            moc.trySave(errorFrom: "PhotoView", error: "Cannot change value of photo \(photo.name)")
                            Cloud.shared.modifyOnCloud(photo: photo)
                            edit.toggle()
                        }.disabled(editingPhoto == nil)
                    }
                }
            }
        }
        .onDisappear{
            // MARK: Cloud save
            for photo in photos {
                guard photo.managedObjectContext == nil else { continue }
                moc.insert(photo)
                Cloud.shared.saveToCloud(recordType: Cloud.RecordType.photos, photo: photo){ recordID in
                    photo.recordID = recordID
                }
            }
            moc.trySave(errorFrom: "photoView", error: "Cannot saved photos")
        }
    }
}
