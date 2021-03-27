//
//  PhotoView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 25/03/2021.
//

import SwiftUI
import CoreData.NSManagedObjectContext

struct PhotoView: View {
    @Environment(\.managedObjectContext) var moc
    
    @State private var show: Bool = false
    @State private var photos: [MyPhoto]
    private var protoID: Int
    private var lastPhotoIndex: Int
    
    init(protoID: Int, photoIndex: Int, photos: [MyPhoto]){
        self.protoID = protoID
        self.lastPhotoIndex = photoIndex
        _photos = State(initialValue: photos)
    }
    
    var body: some View {
        ZStack{
            NavigationLink(destination: PhotosView(photos: $photos, lastPhotoIndex: lastPhotoIndex, protoID: protoID)
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
                ImagePicker(isShow: $showPicker, photos: $photos, lastPhotoIndex: $lastPhotoIndex, protoID: protoID, source: source)
            }
            
            ForEach(photos, id:\.self) { photo in
                HStack{
                    ImageView(photo: photo)
                    Divider()
                    Text(String(photo.value))
                }
            }.onDelete(perform: deletePhoto)
        }
        .onDisappear{
            // MARK: TODO: Cloud save
            print("PhotoView, photos count", photos.count)
            for photo in photos {
                guard photo.managedObjectContext == nil else { continue }
                moc.insert(photo)
                CloudHelper.shared.saveToCloud(recordType: CloudHelper.RecordType.photos, photo: photo){ recordID in
                    photo.recordID = recordID
                }
//                Cloud.savePhoto(protoID: Int(photo.protoID), value: photo.value, name: Int(photo.name), path: path) { res in
//                    switch res {
//                        case .failure(let err):
//                            printError(from: "cloud savePhoto", message: err.localizedDescription)
//                            return
//
//                        case .success(_):
//                            print("Photo saved on cloud")
//                    }
//                }
            }
            moc.trySave(errorFrom: "photoView", error: "Cannot saved photos")
        }
        .onAppear{
            // MARK: TODO: Cloud fetch
            // on appear fetch new photos
            // MARK: Maybe set into coredata date and fetch only if cloud modification date is newer than coredata date [same for proto?]
//            Cloud.fetchPhoto{ res in
//                switch res {
//                    case.failure(let err):
//                        printError(from: "cloud fetchPhoto", message: err.localizedDescription)
//
//                    case .success(let element):
//                        guard !photos.contains(where: {$0.recordID == element.recordID }) else { return }
//                        let photo = MyPhoto(context: moc)
//                        photo.local = true
//                        photo.name = Int16(element.name)
//                        photo.protoID = Int16(element.protoID)
//                        photo.value = element.value
//                        photo.recordID = element.recordID
//                        do {
//                            try moc.save()
//                            photos.append(photo)
//                        } catch {
//                            printError(from: "cloud fetchPhoto - coreData", message: error.localizedDescription)
//                        }
//                        if element.name > self.lastPhotoIndex {
//                            self.lastPhotoIndex = element.name
//                        }
//                }
//            }
        }
    }
    
    private func deletePhoto(at offsets: IndexSet) {
        for index in offsets {
            let remove = photos[index]
            print(remove)
            guard let recordID = remove.recordID else {
                printError(from: "remove photo", message: "RecordID of photo \(remove.protoID) is nil")
                remove.deleteFromDisk()
                photos.remove(at: index)
                moc.delete(remove)
                moc.trySave(errorFrom: "remove cloud", error: "Cannot saved managed object context")
                return
            }
            CloudHelper.shared.deleteFromCloud(recordID: recordID) { recordID in
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

extension NSManagedObjectContext {
    public func trySave(errorFrom: String, error message: String){
        do {
            try self.save()
        } catch {
            printError(from: errorFrom, message: message)
            print(error)
            return
        }
    }
}
