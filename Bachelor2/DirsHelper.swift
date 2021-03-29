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
    
    func getProtocolOutputDir(protoID: Int) -> URL? {
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
    
    func getConentsOfDir(at path: URL) -> [URL]? {
        do {
            let content = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            return content
        } catch {
            printError(from: "getContentsOfDir", message: error.localizedDescription)
            return nil
        }
    }
    
    private func getSpecificOutputDir(protoID: Int, internalID: Int) -> URL? {
        guard let outputURL = getProtocolOutputDir(protoID: protoID) else { return nil }
        let specific = outputURL.appendingPathComponent(String(internalID))
        guard createDir(at: specific.path) == true else { return nil }
        return specific
    }
    
    func getZipURL(protoID: Int, internalID: Int) -> URL? {
        guard let specific = getSpecificOutputDir(protoID: protoID, internalID: internalID) else { return nil }
        return specific.appendingPathComponent("photos.zip")
    }
}
