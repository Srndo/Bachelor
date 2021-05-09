//
//  ImagePicker2.swift
//  Bachelor2
//
//  Created by Simon Sestak on 04/04/2021.
//  Copyright © 2020 Simon Sestak. All rights reserved.
//

import CoreData
import SwiftUI

class PhotoPickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isShow: Bool
    @Binding var photos: [MyPhoto]
    @Binding var index: Int
    @Binding var locked: Bool
    var protoID: Int
    
    init(isShow: Binding<Bool>, photos: Binding<[MyPhoto]>, protoID: Int, lastPhotoIndex: Binding<Int>, locked: Binding<Bool>) {
        _isShow = isShow
        _photos = photos
        _index = lastPhotoIndex
        _locked = locked
        self.protoID = protoID
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        locked = true
        DispatchQueue.global().async {
            guard let uiimage = info[.originalImage] as? UIImage else { return }
            let rotatedImage = self.fixImageOrientation(uiimage)
            if let cgimage = rotatedImage.cgImage {
                TextRecognizer.shared.recognize(name: self.index, image: cgimage) { (name, value) in
                    self.createMyPhoto(uiimage: uiimage, name: name, valueString: value)
                }
            } else {
                printError(from: "image picker", message: "Cannot make auto recognition of value.")
                self.createMyPhoto(uiimage: uiimage, name: self.index)
            }
            self.index = self.index + 1
        }
        isShow = false
    }
    
    func fixImageOrientation(_ image: UIImage)->UIImage {
//        https://stackoverflow.com/a/45476420
        UIGraphicsBeginImageContext(image.size)
        image.draw(at: .zero)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isShow = false
    }
    
    private func createMyPhoto(uiimage: UIImage, name: Int, valueString: String = "-1.0") {
        DispatchQueue.main.async {
            let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let photo = MyPhoto(context: moc)
            let value = Double(valueString)
            photo.savePhoto(toCloud: true, photo: uiimage, protoID: self.protoID, name: name, value: value ?? -1.0, diameter: 50.0) {
                moc.trySave(savingFrom: "savePhoto", errorFrom: "savePhoto", error: "Cannot saved new photo")
            }
            self.photos.append(photo)
            self.locked = false
        }
    }
    
    private func recognizedValue(name: Int, recognized: [Int:String]?) -> Double {
        guard let recognized = recognized else { return -1.0 }
        guard let valString = recognized[name] else { return -1.0 }
        guard let value = Double(valString) else { return -1.0 }
        return value
    }
}

struct PhotoPicker: UIViewControllerRepresentable{
    @Binding var isShow: Bool
    @Binding var photos: [MyPhoto]
    @Binding var lastPhotoIndex: Int
    @Binding var locked: Bool
    var protoID: Int
    
    var source: UIImagePickerController.SourceType
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<PhotoPicker>) {
    }
    
    func makeCoordinator() -> PhotoPickerCoordinator {
        return PhotoPickerCoordinator(isShow: $isShow, photos: $photos, protoID: protoID, lastPhotoIndex: $lastPhotoIndex, locked: $locked)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<PhotoPicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = source
        picker.delegate = context.coordinator
        return picker
    }
}
