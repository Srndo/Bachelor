//
//  PhotoView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 25/03/2021.
//

import SwiftUI

struct PhotoView: View {
    @Environment(\.managedObjectContext) var moc
    
    @State private var show: Bool = false
    @Binding var photos: [MyPhoto]
    @Binding var locked: Bool
    var lastPhotoIndex: Binding<Int>
    private var protoID: Int
    private var internalID: Int
    
    
    init(protoID: Int, internalID: Int, photos: Binding<[MyPhoto]>, lastPhotoIndex: Binding<Int>, locked: Binding<Bool> ){
        self.protoID = protoID
        self.internalID = internalID
        self.lastPhotoIndex = lastPhotoIndex
        _photos = photos
        _locked = locked
    }
    
    var body: some View {
        ZStack{
            NavigationLink(destination: PhotosView(photos: $photos, lastPhotoIndex: lastPhotoIndex, protoID: protoID, internalID: internalID, locked: $locked)
                            .environment(\.managedObjectContext , moc)
            ){
                EmptyView()
            }
            .hidden()
            .frame(width: 0)
            
            HStack{
                Button(action:{
                    self.show.toggle()
                }){
                    Text("Fotky")
                        .bold()
                        .foregroundColor(photos.isEmpty ? Color.orange : Color.green)
                }
                Spacer()
                Image(systemName: "photo.on.rectangle").foregroundColor(photos.isEmpty ? Color.orange : Color.green)
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
    @Binding var lastPhotoIndex: Int
    
    var protoID: Int
    var internalID: Int
    
    @State private var edit: Bool = false
    @State private var editingPhoto: MyPhoto?
    
    @Binding var locked: Bool
    
    @State private var refresh: Bool = false // ugly way 
    
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
                    .disabled(locked)
                    .foregroundColor(.white)
                    .background(locked ? Color.gray : Color.blue)
                    .cornerRadius(10)
                    Spacer()
                }
                .actionSheet(isPresented: $actionShow){
                    actionSheet()
                }
                .sheet(isPresented: $showPicker){
                    if source == UIImagePickerController.SourceType.photoLibrary {
                        ImagePicker(isShow: $showPicker, photos: $photos, lastPhotoIndex: $lastPhotoIndex, locked: $locked, protoID: protoID)
                    } else {
                        PhotoPicker(isShow: $showPicker, photos: $photos, lastPhotoIndex: $lastPhotoIndex, locked: $locked, protoID: protoID, source: source)
                    }
                }
            }
            
            Section(header: Text("Pre zmenu hodnoty alebo popisu 2x tukni na hodnotu.\nPre načítanie fotky 2x tukni na fotku.")){
                ForEach(photos, id:\.self) { photo in
                    HStack{
                        ImageView(photo: photo)
                            .highPriorityGesture(TapGesture(count: 2) .onEnded {
                                if !photo.local {
                                    getZipPhotos()
                                    refresh.toggle()
                                }
                            })
                        Divider()
                        VStack(alignment: .center) {
                            Text("Hodnota")
                            Text("\(photo.value, specifier: "%.2f")")
                            Spacer()
                            Text("Popis")
                            Text("\(photo.descriptionOfPlace)")
                            Spacer()
                            Text("Veľkosť terča")
                            Text("\(photo.targetDiameter, specifier: "%.2f")")
                        }.highPriorityGesture(TapGesture(count: 2).onEnded {
                            guard locked != true else { return }
                            self.edit.toggle()
                            editingPhoto = photo
                        })
                    }
                }.onDelete(perform: deletePhoto)
                Text(String(refresh)).hidden()
            }
        }
        .sheet(isPresented: $edit) {
            EditingView(editingPhoto: $editingPhoto, show: $edit, refresh: $refresh).environment(\.managedObjectContext , moc)
        }
    }
}

struct EditingView: View {
    @Environment(\.managedObjectContext) var moc
    @State private var newValue: String = ""
    @State private var newDesc: String = ""
    @State private var newDiameter: String = ""
    @State private var placeholder: String = "Zadajte hodnotu"
    
    @Binding var editingPhoto: MyPhoto?
    @Binding var show: Bool
    @Binding var refresh: Bool
    
    var body: some View {
        Form{
            Section{
                TextField(placeholder, text: $newValue)
                    .onChange(of: newValue, perform: { _ in
                        guard let value = Double(newValue) else { return }
                        if value < 0.0 {
                            placeholder = "Prosim zadajte znova"
                            newValue = ""
                        }
                    })
                TextField("Zadajte popis meracieho miesta", text: $newDesc)
                TextField("Zadajte veľkosť terča", text: $newDiameter)
                Button("Ulož"){
                    guard let photo = editingPhoto else { return }
                    guard let value = Double(newValue) else { return }
                    photo.value = value
                    photo.descriptionOfPlace = newDesc
                    if !newDiameter.isEmpty, let diameter = Double(newDiameter) {
                        photo.targetDiameter = diameter
                    }
                    moc.trySave(savingFrom: "edit photo value", errorFrom: "PhotoView", error: "Cannot change value of photo \(photo.name)")
                    Cloud.shared.modifyOnCloud(photo: photo)
                    show.toggle()
                    refresh.toggle()
                }
            }
        }
        .onAppear{
            guard let photo = editingPhoto else {
                show.toggle()
                return
            }
            newValue = String(photo.value)
            newDesc = photo.descriptionOfPlace
            newDiameter = String(photo.targetDiameter)
        }
    }
}
