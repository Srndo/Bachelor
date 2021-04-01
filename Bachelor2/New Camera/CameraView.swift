//
//  CameraView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 31/03/2021.
//
import SwiftUI
import UIKit
import AVFoundation
import Vision

class Model: ObservableObject {
    @Published var image: UIImage?
    @Published var text: String = "Hodnota"
    @Published var color: Color = .red
    var session: AVCaptureSession?
    
    func reset() {
        stop()
        color = .red
        text = "Hodnota"
        image = nil
    }
    
    func takePhoto() {
        stop()
        text = ""
        color = .green
        // todo take photo
    }
    
    private func stop(){
        guard let session = session else { return }
        if session.isRunning {
            session.stopRunning()
        }
    }
}

struct CapturedView: View {
    @ObservedObject var model = Model()

    @State var isShowingCameraView = false
    
    var body: some View {
        CameraView(model: model)
            .edgesIgnoringSafeArea(.all)
            .hidden(model.image != nil)
        VStack{
            Spacer()
            Image(uiImage: model.image ?? UIImage()).resizable().scaledToFit()
            Spacer()
            Text("\(model.text)").foregroundColor(model.color)
            if model.color == .red {
                Button(action: {
                    model.takePhoto()
                }, label: {Image(systemName: "camera.circle.fill")})
            } else {
                Button("Uloz") { }
            }
        }.onTapGesture { model.reset() }
    }
}

struct CameraView : UIViewControllerRepresentable {
    let model: Model
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CameraView>) -> UIViewController {
        let controller = NumberDetectorViewController()
        controller.model = self.model
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraView.UIViewControllerType, context: UIViewControllerRepresentableContext<CameraView>) {
    }
}

class VisionViewController {
    var request: VNRecognizeTextRequest!
    var model: Model?
    
    init(model: Model? = nil) {
        self.model = model
        request = VNRecognizeTextRequest(completionHandler: recognizeTextHandler)
    }
    
    func recognizeTextHandler(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNRecognizedTextObservation] else {
            return
        }
        let maximumCandidates = 1
        
        for observation in results {
            // find top candidate in observation
            guard let candidate = observation.topCandidates(maximumCandidates).first else { continue }
            // check if the first candidate contains numbers
            print("Confidence \(candidate.confidence)", candidate.string)
            guard candidate.confidence >= 0.65 else { continue }
            guard candidate.string.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil else { continue }
            print("Numbers found: \(candidate.string)")
            // add number candidate
            if let model = model, let session = model.session, session.isRunning {
                session.stopRunning()
            }
            DispatchQueue.main.async {
                if let model = self.model, model.color == .red {
                    model.text = candidate.string
                    model.color = .green
                }
            }
        }
    }
}

class NumberDetectorViewController : UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var model: Model?
    var currentOrientation = UIDeviceOrientation.portrait
    // Orientation of text to search for in the region of interest.
    var textOrientation = CGImagePropertyOrientation.up
    var cameraPreview: AVCaptureVideoPreviewLayer?
    
//    var bufferAspectRatio: Double!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let model = model else { return }
        model.session = AVCaptureSession()
        guard let session = model.session else { return }
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        startLiveVideo()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let cameraPreview = cameraPreview else { return }
        let deviceOrientation = UIDevice.current.orientation
        if let videoPreviewLayerConnection = cameraPreview.connection {
            if let newVideoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue) {
                videoPreviewLayerConnection.videoOrientation = newVideoOrientation
            }
        }
    }
    
    func startLiveVideo() {
        guard let model = model else { return }
        guard let session = model.session else { return }
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else {
            print("Could not create capture device.")
            return
        }
//
//        if captureDevice.supportsSessionPreset(.hd4K3840x2160) {
//            model.session.sessionPreset = AVCaptureSession.Preset.hd4K3840x2160
//            bufferAspectRatio = 3840.0 / 2160.0
//        } else {
//            model.session.sessionPreset = AVCaptureSession.Preset.hd1920x1080
//            bufferAspectRatio = 1920.0 / 1080.0
//        }
                
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice)
        let deviceOutput = AVCaptureVideoDataOutput()
        
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] //
        if session.canAddInput(deviceInput){
            session.addInput(deviceInput)
        }
        if session.canAddOutput(deviceOutput) {
            session.addOutput(deviceOutput)
            deviceOutput.connection(with: AVMediaType.video)?.preferredVideoStabilizationMode = .off
        } else {
            print("Could not add VDO output")
            return
        }

        cameraPreview = AVCaptureVideoPreviewLayer(session: session)
        
        view.layer.addSublayer(cameraPreview!)
        cameraPreview!.frame = view.frame

        session.startRunning()
    }
    
    // Convert CIImage to CGImage
    private func convert(cmage:CIImage) -> UIImage {
         let context:CIContext = CIContext.init(options: nil)
         let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
         let image:UIImage = UIImage.init(cgImage: cgImage)
         return image
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let vision = VisionViewController(model: model)
        if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            // Configure for running in real-time.
            vision.request.recognitionLevel = .accurate
//            vision.request.usesLanguageCorrection = false
            let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: textOrientation, options: [:])
            do {
                try requestHandler.perform([vision.request])
            } catch {
                print(error)
            }
        }
        
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
        let rotatedCIImage = ciimage.oriented(forExifOrientation: Int32(CGImagePropertyOrientation.right.rawValue))
        let image : UIImage = self.convert(cmage: rotatedCIImage)
        DispatchQueue.main.async {
            guard let model = self.model else { return }
            guard let session = model.session else { return }
            if !session.isRunning && model.image == nil{
                model.image = image
            }
        }
    }
}

extension View {
    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}
