//
//  Extensions.swift
//  Bachelor2
//
//  Created by Simon Sestak on 23/03/2021.
//

import SwiftUI

extension Int {
    var _bound: Int {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return String(_bound)
        }
        set {
            _bound = Int(newValue) ?? 0
        }
    }
}

extension Double {
    var _bound: Double {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    public var bound: String {
        get {
            return String(_bound)
        }
        set {
            _bound = Double(newValue) ?? 0.0
        }
    }
}

extension Proto {
    func disabled() -> Bool {
        if id != -1 && creationDate != nil && client.filled() && construction.filled() && device.filled() && method.filled() && material.filled() {
            return false
        }
        return true
    }
}

extension Material {
    func filled() -> Bool {
        return !material.isEmpty
    }
}

extension MyMethod {
    func filled() -> Bool {
        return !(name.isEmpty || requestedValue <= 0.0)
    }
}

extension Device {
    func filled() -> Bool {
        return !(serialNumber.isEmpty || name.isEmpty || manufacturer.isEmpty)
    }
}

extension Construction {
    func filled() -> Bool {
        return !(name.isEmpty || address.isEmpty)
    }
}

extension Company {
    func filled() -> Bool {
        return !(ico.bound.isEmpty || dic.bound.isEmpty || name.isEmpty || address.isEmpty)
    }
}

extension Photo {
    mutating func saveToDisk(photo: UIImage?, name: String) {
        guard let img = photo else { print("ERROR [save photo]: \(name) for save is nil."); return }
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { print("ERROR [save photo]: Documents directory is nil"); return }
        
        self.name = name
        self.relativePath = "Images/" + name + ".png"
        let imagePath = docURL.appendingPathComponent(self.relativePath)
        
        DispatchQueue.global().async {
            guard let data = img.jpegData(compressionQuality: 0.1) else { print("ERROR [save photo]: Cannot convert \(name) to data"); return }
            
            do {
                try data.write(to: imagePath)
            } catch {
                print("ERROR [save photo]: Cannot write \(name) to disk")
                print(error)
                return
            }
            print("Photo \(name) saved")
        }
    }
    
    func asynLoadFromDisk(completitionBlock: @escaping (Image) -> ()) {
        DispatchQueue.global().async {
            guard self.relativePath != "" else { print("ERROR: [photo load]: Path of \(self.name) is empty"); return }
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { print("ERROR [photo save]: Documents directory is nil"); return }
            let imagePath = docURL.appendingPathComponent(self.relativePath)
            if let uiimage = UIImage(contentsOfFile: imagePath.path){
                DispatchQueue.main.async {
                    completitionBlock(Image(uiImage: uiimage))
                }
            }
            DispatchQueue.main.async {
                completitionBlock(Image(systemName: "photo"))
            }
        }
    }
    
    func deleteFromDisk() {
        DispatchQueue.global().async {
            guard self.relativePath != "" else { print("ERROR [delete photo]: Path of \(self.name) is empty"); return }
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { print("ERROR [delete photo]: Documents directory is nil"); return }
            let url = docURL.appendingPathComponent(self.relativePath)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("ERROR [delete photo]: Cannot delete \(self.name) from disk")
                print(error)
                return
            }
            print("Photo deleted")
        }
    }
}

