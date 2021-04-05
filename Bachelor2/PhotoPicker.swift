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
    var protoID: Int
    
    init(isShow: Binding<Bool>, photos: Binding<[MyPhoto]>, protoID: Int, lastPhotoIndex: Binding<Int>) {
        _isShow = isShow
        _photos = photos
        _index = lastPhotoIndex
        self.protoID = protoID
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        DispatchQueue.global().async {
            guard let uiimage = info[.originalImage] as? UIImage else { return }
            let rotatedImage = self.fixImageOrientation(uiimage)
            if let cgImage = rotatedImage.cgImage {
                var dic = [Int:CGImage]()
                self.index = self.index + 1
                dic[self.index] = cgImage
                TextRecognizer().regognize(from: dic) { recognized in
                    self.createMyPhoto(uiimage: uiimage, recognized:  recognized)
                }
            } else {
                printError(from: "image picker", message: "Cannot make auto recognition of value.")
                self.createMyPhoto(uiimage: uiimage)
            }
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
    
    private func createMyPhoto(uiimage: UIImage?, recognized: [Int:String]? = nil ) {
        let photo = MyPhoto(entity: MyPhoto.entity(), insertInto: nil)
        photo.savePhotoToDisk(photo: uiimage, protoID: self.protoID, name: self.index, value: self.recognizedValue(name: self.index, recognized: recognized), diameter: 50.0)
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

struct PhotoPicker: UIViewControllerRepresentable{
    @Binding var isShow: Bool
    @Binding var photos: [MyPhoto]
    @Binding var lastPhotoIndex: Int
    var protoID: Int
    
    var source: UIImagePickerController.SourceType
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<PhotoPicker>) {
    }
    
    func makeCoordinator() -> PhotoPickerCoordinator {
        return PhotoPickerCoordinator(isShow: $isShow, photos: $photos, protoID: protoID, lastPhotoIndex: $lastPhotoIndex)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<PhotoPicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = source
        picker.delegate = context.coordinator
        return picker
    }
}
