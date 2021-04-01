//
//  TextRecognizer.swift
//  Bachelor2
//
//  Created by Simon Sestak on 30/03/2021.
//

import Vision
import SwiftUI

// MARK: TODO: Rotated foto to left recognize value
struct TextRecognizer {
    func regognize(from images: [Int:CGImage], completititon: @escaping ([Int:String]) -> ()) {
        DispatchQueue.global().async {
            var recognizedValues: [Int:String] = [:]
            var returnConfidence: Float = 0.5
            var returnNumber = "-1.0"
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("The observations are of an unexpected type.")
                    return
                }
                let maximumCandidates = 1
                // Iterate throught finded observations
                for observation in observations {
                    // find top candidate in observation
                    guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                    // check if the first candidate contains numbers
                    print("Confidence \(candidate.confidence)", candidate.string)
                    guard candidate.confidence >= returnConfidence else { continue }
                    guard candidate.string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil else { continue }
                    returnConfidence = candidate.confidence
                    returnNumber = candidate.string
                    print("Numbers found: \(candidate.string)")
                }
            }
            
            request.recognitionLevel = .accurate
//            request.usesLanguageCorrection = false
            
            for (name,image) in images {
                let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])

                do {
                    try requestHandler.perform([request])
                    recognizedValues[name] = returnNumber
                    returnNumber = ""
                } catch {
                    printError(from: "recognize", message: error.localizedDescription)
                }
            }
            DispatchQueue.main.async {
                completititon(recognizedValues)
            }
        }
    }
}

