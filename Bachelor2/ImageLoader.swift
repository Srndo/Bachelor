//
//  ImageLoader.swift
//  Bachelor2
//
//  Created by Simon Sestak on 25/03/2021.
//

import SwiftUI

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    func load(photo: MyPhoto){
        DispatchQueue.global().async{
            guard let imagePath = photo.getPhotoPath() else { return }
            guard let image = UIImage(contentsOfFile: imagePath.path) else { return }
            DispatchQueue.main.async{
                self.image = image
            }
        }
    }
}

struct ImageView: View {
    @ObservedObject var imageLoader = ImageLoader()
    var placeholder: Image
    
    init(photo: MyPhoto, placeholder: Image = Image("placeholderImage")) {
        self.placeholder = placeholder
        self.imageLoader.load(photo: photo)
    }
    
    var body: some View {
        if let uiimage = imageLoader.image {
            return Image(uiImage: uiimage).resizable().scaledToFit()
        } else {
            return placeholder.resizable().scaledToFit()
        }
    }
}
