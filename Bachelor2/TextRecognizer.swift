//
//  TextRecognizer.swift
//  Bachelor2
//
//  Created by Simon Sestak on 30/03/2021.
//

import Vision
import SwiftUI

class TextRecognizer {
    static let shared = TextRecognizer()
    
    private let mnistModel: VNCoreMLModel?
    private var modelNumbers: [Int : NumberWithConfidence] = [:]
    private var textNumbers: [Int : NumberWithConfidence] = [:]
    
    struct NumberWithConfidence {
        let number: String
        let confidence: VNConfidence
    }
    
    init() {
        if let mnistModel = try? VNCoreMLModel(for: MNISTClassifier().model) {
            self.mnistModel = mnistModel
        } else {
            print("Cannot open MNIST model")
            self.mnistModel = nil
        }
    }
    
    private func recognizeWithModel(name: Int, image: CGImage) {
        guard let model = mnistModel else { return }
//        DispatchQueue.global().async {
            let request = VNCoreMLRequest(model: model) {(request, error) in
                guard let observations = request.results as? [VNClassificationObservation] else {
                    print("The observations are of an unexpected type.")
                    return
                }
                var number = ""
                var first = true
                var confidence: VNConfidence = 0.0
                for candidate in observations {
                    guard candidate.confidence >= 0.0001 else { continue }
                    number += candidate.identifier
                    confidence += candidate.confidence
                    if first {
                        number += "."
                        first = false
                    }
                }
                let count: Int = number.contains(".") ? number.count - 1 : number.count
                confidence = confidence / Float(count)
                
                self.modelNumbers[name] = NumberWithConfidence(number: number, confidence: confidence)
                print("MNIST number found: \(number)")
            }
            
            let requestHandler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
            do{
                try requestHandler.perform([request])
            } catch {
                printError(from: "recognizeText", message: error.localizedDescription)
            }
//        }
    }
    
    private func recognizeText(name: Int, image: CGImage) {
//        DispatchQueue.global().async {
            var returnConfidence: Float = 0.5
            let request = VNRecognizeTextRequest { (request, error) in
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    print("The observations are of an unexpected type.")
                    return
                }
                let maximumCandidates = 1

                for observation in observations {
                    guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
                    guard candidate.confidence >= returnConfidence else { continue }
                    guard candidate.string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil else { continue }
                    returnConfidence = candidate.confidence
                    self.textNumbers[name] = NumberWithConfidence(number: candidate.string, confidence: candidate.confidence)
                    print("Numbers found: \(candidate.string)")
                }
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            
            let requestHandler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
            do{
                try requestHandler.perform([request])
            } catch {
                printError(from: "recognizeText", message: error.localizedDescription)
            }
//        }
    }
    
    func recognize(name: Int, image: CGImage?, completition: @escaping (Int, String) -> ()) {
        DispatchQueue.global().async {
            guard let image = image else { return }
            var recognizedValues = [Int : String]()
            self.modelNumbers[name] = NumberWithConfidence(number: "-1.0", confidence: VNConfidence(0))
            self.textNumbers[name] = NumberWithConfidence(number: "-1.0", confidence: VNConfidence(0))
            
            self.recognizeWithModel(name: name, image: image)
            self.recognizeText(name: name, image: image)
            
            if let modelNumber = self.modelNumbers[name], let textNumber = self.textNumbers[name] {
                recognizedValues[name] = modelNumber.confidence >= textNumber.confidence ? modelNumber.number : textNumber.number
            }
            
            DispatchQueue.main.async {
                completition(name, recognizedValues[name] ?? "-1.0")
            }
        }
    }
}
