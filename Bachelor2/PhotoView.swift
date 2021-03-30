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
    private var protoID: Int
    private var internalID: Int
    private var lastPhotoIndex: Int
    
    init(protoID: Int, internalID: Int, photoIndex: Int, photos: [MyPhoto]){
        self.protoID = protoID
        self.lastPhotoIndex = photoIndex
        self.internalID = internalID
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
    @State private var showPicker: Bool = false
    @State private var source: UIImagePickerController.SourceType = .photoLibrary
    @Binding var photos: [MyPhoto]
    @State var lastPhotoIndex: Int
    @State var protoID: Int
    @State var internalID: Int
    @State private var showAllert: Bool = false
    
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
                actionSheet()
            }
            .sheet(isPresented: $showPicker){
                // MARK: TODO: ImagePicker
                // find the value in photo
                ImagePicker(isShow: $showPicker, photos: $photos, lastPhotoIndex: $lastPhotoIndex, protoID: protoID, source: source)
            }
            
            ForEach(photos, id:\.self) { photo in
                HStack{
                    ImageView(photo: photo).onTapGesture {
                        // MARK: TODO: ZIP Extraction
                        return 
                        // allert if user wanna save copy of photo saved in last output
                        if !photo.local {
                            // else downlaod zip from cloud and get contetn of it to Document/Images/{proto.ID}
                        }
                        // if check if zip with internalID exist and get content of it to Document/Images/{proto.ID}
                        if let zipURL = Dirs.shared.getZipURL(protoID: protoID, internalID: internalID) {
                            getZipPhotos(zipURL: zipURL)
                        }
                    }
                    Divider()
                    Text(String(photo.value))
                }
            }.onDelete(perform: deletePhoto)
        }
//        .alert(isPresented: <#T##Binding<Bool>#>, content: <#T##() -> Alert#>)
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
    
    private func actionSheet() -> ActionSheet {
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
    
    private func getZipPhotos(zipURL: URL) {
        guard let specificOutput = Dirs.shared.getSpecificOutputDir(protoID: protoID, internalID: internalID) else { return }
        do {
            try Zip.unzipFile(zipURL, destination: specificOutput, overwrite: true, password: nil)
            insertExtractedPhotosToCoreData(from: specificOutput)
        } catch {
            printError(from: "getZipPhotos", message: error.localizedDescription)
            return
        }
    }
    
    private func insertExtractedPhotosToCoreData(from: URL){
        let _ = Dirs.shared.getConentsOfDir(at: from)
        
    }
    
    private func deletePhoto(at offsets: IndexSet) {
        for index in offsets {
            let remove = photos[index]
            guard let recordID = remove.recordID else {
                print("Warning [remove photo]: RecordID of photo \(remove.protoID) is nil")
                remove.deleteFromDisk()
                photos.remove(at: index)
                moc.delete(remove)
                moc.trySave(errorFrom: "remove cloud", error: "Cannot saved managed object context")
                return
            }
            Cloud.shared.deleteFromCloud(recordID: recordID) { recordID in
                guard let recordID = recordID else { return }
                guard let removeCloud = photos.first(where: { $0.recordID == recordID }) else {
                    printError(from: "remove photo cloud", message: "RecordID returned from cloud not exist in photos contained by proto")
                    return
                }
                guard removeCloud == remove else {
                    printError(from: "remove cloud", message: "Marked protocol to remove and returned from cloud is not same")
                    return
                }
                remove.deleteFromDisk()
                photos.remove(at: index)
                moc.delete(remove)
                moc.trySave(errorFrom: "remove cloud", error: "Cannot saved managed object context")
            }
        }
    }
}
