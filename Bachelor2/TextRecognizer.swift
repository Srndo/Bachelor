//
//  TextRecognizer.swift
//  Bachelor2
//
//  Created by Simon Sestak on 30/03/2021.
//

import Vision
import SwiftUI

struct TextRecognizer {
    func regognize(from images: [Int:CGImage], completititon: @escaping ([Int:String]) -> ()) {
        DispatchQueue.global().async {
            var recognizedValues: [Int:String] = [:]
            var tmp = ""
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
                    guard candidate.confidence >= 0.65 else { continue }
                    guard candidate.string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil else { continue }
                    print("Numbers found: \(candidate.string)")
                    // add number candidate
                    tmp += candidate.string
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            for (name,image) in images {
                let requestHandler = VNImageRequestHandler(cgImage: image, options: [:])

                do {
                    try requestHandler.perform([request])
                    recognizedValues[name] = tmp
                    tmp = ""
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

