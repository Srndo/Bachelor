//
//  LogoPicker.swift
//  Bachelor2
//
//  Created by Simon Sestak on 05/04/2021.
//

import SwiftUI

class LogoPickerCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isShow: Bool
    @Binding var logo: UIImage?
    
    init(isShow: Binding<Bool>, logo: Binding<UIImage?>) {
        _isShow = isShow
        _logo = logo
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        isShow = false
        guard let uiimage = info[.originalImage] as? UIImage else { return }
        logo = uiimage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isShow = false
    }
}

struct LogoPicker: UIViewControllerRepresentable{
    @Binding var isShow: Bool
    @Binding var logo: UIImage?
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<LogoPicker>) {}
    
    func makeCoordinator() -> LogoPickerCoordinator {
        return LogoPickerCoordinator(isShow: $isShow, logo: $logo)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<LogoPicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
}
