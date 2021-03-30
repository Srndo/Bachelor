//
//  ImagePicker.swift
//  Bachelor2
//
//  Created by Simon Sestak on 30/10/2020.
//  Copyright © 2020 Simon Sestak. All rights reserved.
//

import CoreData
import SwiftUI

class ImagePickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isShow: Bool
    @Binding var photos: [MyPhoto]
    var index: Int
    var protoID: Int
    
    init(isShow: Binding<Bool>, photos: Binding<[MyPhoto]>, protoID: Int, lastPhotoIndex: Binding<Int>) {
        _isShow = isShow
        _photos = photos
        index = lastPhotoIndex.wrappedValue + 1
        self.protoID = protoID
        lastPhotoIndex.wrappedValue = lastPhotoIndex.wrappedValue + 1
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let uiimage = info[.originalImage] as? UIImage else { return }
        if let cgImage = uiimage.cgImage {
            var dic = [Int:CGImage]()
            dic[self.index] = cgImage
            TextRecognizer().regognize(from: dic) { recognized in
                self.createMyPhoto(uiimage: uiimage, recognized:  recognized)
            }
        } else {
            printError(from: "image picker", message: "Cannot make auto recognition of value.")
            createMyPhoto(uiimage: uiimage)
        }
        isShow = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isShow = false
    }
    
    private func createMyPhoto(uiimage: UIImage?, recognized: [Int:String]? = nil ) {
        let photo = MyPhoto(entity: MyPhoto.entity(), insertInto: nil)
        photo.savePhotoToDisk(photo: uiimage, protoID: self.protoID, name: self.index, value: self.recognizedValue(name: self.index, recognized: recognized))
        DispatchQueue.main.async {
            self.photos.append(photo)
        }
    }
    
    private func recognizedValue(name: Int, recognized: [Int:String]?) -> Double {
        guard let recognized = recognized else { return -1.0 }
        guard let valString = recognized[name] else { return -1.0 }
        guard let value = Double(valString) else { return -1.0 }
        return value
    }
}

struct ImagePicker: UIViewControllerRepresentable{
    @Binding var isShow: Bool
    @Binding var photos: [MyPhoto]
    @Binding var lastPhotoIndex: Int
    var protoID: Int
    
    var source: UIImagePickerController.SourceType
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
    }
    
    func makeCoordinator() -> ImagePickerCoordinator {
        return ImagePickerCoordinator(isShow: $isShow, photos: $photos, protoID: protoID, lastPhotoIndex: $lastPhotoIndex)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = source
        picker.delegate = context.coordinator
        return picker
    }
}
