//
//  DirsHelper.swift
//  Bachelor2
//
//  Created by Simon Sestak on 26/03/2021.
//

import Foundation

class Dirs {
    static let shared = Dirs()
    private let fileManager = FileManager.default
    
    private func getDocumentsDir() -> URL? {
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docURL = documentsDirectory else { printError(from: "getDocumentsDir", message: "Documents directory is nil"); return nil}
        return docURL
    }
    
    func getImagesDir() -> URL? {
        guard let docURL = getDocumentsDir() else { return nil }
        let imagesURL = docURL.appendingPathComponent("Images")
        return imagesURL
    }
    
    func getProtosDir() -> URL? {
        guard let docURL = getDocumentsDir() else { return nil }
        let protosURL = docURL.appendingPathComponent("Documents")
        return protosURL
    }

    func getOutputDir() -> URL? {
        guard let docURL = getDocumentsDir() else { return nil }
        let outputURL = docURL.appendingPathComponent("Output")
        return outputURL
    }
    
    func getSpecificOutputDir(protoID: Int) -> URL? {
        guard let docURL = getOutputDir() else { return nil }
        let outputURL = docURL.appendingPathComponent(String(protoID))
        
        let created = createDir(at: outputURL.path)
        
        if !created {
            return nil
        }
        
        return outputURL
    }
    
    func getSpecificPhotoDir(protoID: Int) -> URL? {
        guard let docURL = getImagesDir() else { return nil }
        let imagesURL = docURL.appendingPathComponent(String(protoID))
        
        let created = createDir(at: imagesURL.path)
        
        if !created {
            return nil
        }
        return imagesURL
    }
    
    func createDir(at path: String) -> Bool {
        if !fileManager.fileExists(atPath: path) {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                printError(from: "create dir", message: error.localizedDescription)
                return false
            }
        }
        return true
    }
}
