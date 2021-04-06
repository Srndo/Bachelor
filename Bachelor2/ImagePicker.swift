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
    var protoID: Int
    
    func makeCoordinator() -> ImagePickerCoordinator {
        return ImagePickerCoordinator(isShow: $isShow, photos: $photos, protoID: protoID, lastPhotoIndex: $lastPhotoIndex)
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
    var protoID: Int
    
    init(isShow: Binding<Bool>, photos: Binding<[MyPhoto]>, protoID: Int, lastPhotoIndex: Binding<Int>) {
        _isShow = isShow
        _photos = photos
        _index = lastPhotoIndex
        self.protoID = protoID
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        for photo in results {
            if photo.itemProvider.canLoadObject(ofClass: UIImage.self) {
                photo.itemProvider.loadObject(ofClass: UIImage.self) { image, err in
                    guard let image = image as? UIImage else {
                        printError(from: "Image Picker", message: err?.localizedDescription ?? "")
                        return
                    }
                    if let cgimage = image.cgImage{
                        var dic = [Int:CGImage]()
                        dic[self.index] = cgimage
                        TextRecognizer().regognize(from: dic) { recognized in
                            self.createMyPhoto(uiimage: image, recognized:  recognized)
                        }
                    } else {
                        printError(from: "Image picker", message: "Cannot convert UIImage to CGImage")
                        self.createMyPhoto(uiimage: image)
                    }
                }
            }
        }
        isShow.toggle()
    }
    
    private func createMyPhoto(uiimage: UIImage?, recognized: [Int:String]? = nil ) {
        let photo = MyPhoto(entity: MyPhoto.entity(), insertInto: nil)
        self.index += 1
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
