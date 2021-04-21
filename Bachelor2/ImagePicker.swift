//
//  ImagePicker.swift
//  Bachelor2
//
//  Created by Simon Sestak on 30/10/2020.
//  Copyright © 2020 Simon Sestak. All rights reserved.
//

import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isShow: Bool
    @Binding var photos: [MyPhoto]
    @Binding var lastPhotoIndex: Int
    @Binding var locked: Bool
    var protoID: Int
    
    func makeCoordinator() -> ImagePickerCoordinator {
        return ImagePickerCoordinator(isShow: $isShow, photos: $photos, protoID: protoID, lastPhotoIndex: $lastPhotoIndex, locked: $locked)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
}

class ImagePickerCoordinator: NSObject, PHPickerViewControllerDelegate {
    @Binding var isShow: Bool
    @Binding var photos: [MyPhoto]
    @Binding var index: Int
    @Binding var locked: Bool
    var protoID: Int
    var end: Int = 0
    
    init(isShow: Binding<Bool>, photos: Binding<[MyPhoto]>, protoID: Int, lastPhotoIndex: Binding<Int>, locked: Binding<Bool>) {
        _isShow = isShow
        _photos = photos
        _index = lastPhotoIndex
        _locked = locked
        self.protoID = protoID
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        locked = true
        end = results.count
        for photo in results {
            if photo.itemProvider.canLoadObject(ofClass: UIImage.self) {
                photo.itemProvider.loadObject(ofClass: UIImage.self) { image, err in
                    guard let image = image as? UIImage else {
                        printError(from: "Image Picker", message: err?.localizedDescription ?? "")
                        return
                    }
                    if let cgimage = image.cgImage{
                        TextRecognizer.shared.recognize(name: self.index, image: cgimage) { (name, value) in
                            self.createMyPhoto(uiimage: image, name: name, valueString: value)
                        }
                    } else {
                        printError(from: "Image picker", message: "Cannot convert UIImage to CGImage")
                        self.createMyPhoto(uiimage: image, name: self.index)
                    }
                    self.index += 1
                }
            }
        }
        isShow.toggle()
    }
    
    private func createMyPhoto(uiimage: UIImage, name: Int, valueString: String = "-1.0") {
        DispatchQueue.main.async {
            let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let photo = MyPhoto(context: moc)
            let value = Double(valueString)
            photo.savePhoto(toCloud: true, photo: uiimage, protoID: self.protoID, name: name, value: value ?? -1.0) {
                moc.trySave(savingFrom: "savePhoto", errorFrom: "savePhoto", error: "Cannot saved new photo")
            }
            self.photos.append(photo)
            self.end -= 1
            if self.end <= 0 {
                self.locked = false
            }
        }
    }
    
    private func recognizedValue(name: Int, recognized: [Int:String]?) -> Double {
        guard let recognized = recognized else { return -1.0 }
        guard let valString = recognized[name - 1] else { return -1.0 }
        guard let value = Double(valString) else { return -1.0 }
        return value
    }
}
