//
//  DirsHelper.swift
//  Bachelor2
//
//  Created by Simon Sestak on 26/03/2021.
//

import Foundation

class Dirs {
    static let shared = Dirs()
    
    private func getDocumentsDir() -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
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
        
        if !FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: outputURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                printError(from: "getSpecificOutputDir", message: error.localizedDescription)
                return nil
            }
        }
        return outputURL
    }
    
    func getSpecificPhotoDir(protoID: Int) -> URL? {
        guard let docURL = getImagesDir() else { return nil }
        let imagesURL = docURL.appendingPathComponent(String(protoID))
        
        if !FileManager.default.fileExists(atPath: imagesURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: imagesURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                printError(from: "getSpecificPhotoDir", message: error.localizedDescription)
                return nil
            }
        }
        
        return imagesURL
    }
}
