//
//  PDFHelper.swift
//  Bachelor2
//
//  Created by Simon Sestak on 03/04/2021.
//

import PDFKit
import SwiftUI

struct PDFKitView: View {
    var data: Data?
    var body: some View {
        PDFKitRepresentedView(data)
    }
}

struct PDFKitRepresentedView: UIViewRepresentable {
    let data: Data?
    init(_ data: Data?) {
        self.data = data
    }

    func makeUIView(context: UIViewRepresentableContext<PDFKitRepresentedView>) -> PDFKitRepresentedView.UIViewType {
        let pdfView = PDFView()
        if let data = self.data {
         pdfView.document = PDFDocument(data: data)
        }
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<PDFKitRepresentedView>) {
        // Update the view.
    }
}

class PDF {
    private let format: UIGraphicsPDFRendererFormat
    private let pageRect: CGRect
    private let renderer: UIGraphicsPDFRenderer
    
    private let sides: CGFloat
    private let midle: CGFloat
    
    private let colWidth: CGFloat
    
    init() {
        format = UIGraphicsPDFRendererFormat()

        // set size of page (A4)
        pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        
        sides = pageRect.width * 0.25
        midle = pageRect.width * 0.5
        
        // width - 20 for padding / 3 cols
        colWidth = (pageRect.width - 20) / 3
        
        // create this page
        renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
    }
    
    func showPDF(version: OutputArchive?) -> AnyView {
        guard let version = version else { return AnyView(EmptyView()) }
        guard let dataURL = Dirs.shared.getPdfURL(protoID: Int(version.protoID), internalID: Int(version.internalID)) else { return AnyView(EmptyView()) }
        guard let data = try? Data(contentsOf: dataURL) else { return AnyView(EmptyView()) }
        return AnyView(PDFKitView(data: data))
    }
    
    func createPDF(proto: Proto, photos: [MyPhoto]) -> Data {
        return renderer.pdfData { (context) in
            context.beginPage()
            let logoCoords = addLogo()
            createTitle(center: logoCoords.center, bottom: logoCoords.bottom)
            
            // start at end of 3th col and at fixed height 30 (optimalized)
            var yForAntoherLine = addText(startAt: colWidth * 2 + 10 , y: 32, width: colWidth, height: logoCoords.bottom, bold: true, body: "Protokol o skúške číslo:\n\n \(proto.id):\(proto.creationDate.showYear())") + 40
            
            yForAntoherLine += createRowOfThirds(bold: true, first: "Druh skúšky:", second: "Stavba:", third: "Číslo dokumentu:", y: yForAntoherLine)
            yForAntoherLine += createRowOfThirds(first: proto.method.type, second: proto.construction.name, third: "\(proto.internalID)", y: yForAntoherLine) + 10 // + padding
            yForAntoherLine += createRowOfThirds(bold: true, first: "Použitá metóda skúšky:", second: "Inštalácia meriaceho zariadenia:", third: "Sledované veličiny:", y: yForAntoherLine)
            yForAntoherLine += createRowOfThirds(first: "Skúška bola zrealizovaná v súlade s pracovným postupom \(proto.workflow.name) \"\(proto.method.type)\"",
                                                 second: "Meracie zariadenie bolo nainštalováné v súlade s pracovným postupom \(proto.workflow.name) \"\(proto.method.type)\"",
                                                 third: proto.method.monitoredDimension,
                                                 y: yForAntoherLine) + 10 // + padding
            yForAntoherLine += createRowOfThirds(bold: true, first: "Použitý merací prístroj:",
                                                 second: "Podklady pre vypracovanie protokolu a údaje o skúšanom objekte:",
                                                 third: "Klimatické podmienky:",
                                                 y: yForAntoherLine)
            yForAntoherLine += createRowOfThirds(first: "Názov: \(proto.device.name)\nVýrobca: \(proto.device.manufacturer)\nVýrobné číslo: \(proto.device.serialNumber)",
                                                 second: "Skúšaný materiál: \(proto.material.material)\n" + (proto.material.base != "" ? "Podklad: \(proto.material.base)\n" : "") + "Zhotoviteľ: \(proto.material.manufacturer)",
                                                 third: "Teplota ovzdušia: \(proto.clima.tempAir) °C\nVlhkosť ovzdušia: \(proto.clima.humAir) %\nTeplota konštrukcie: \(proto.clima.tempCon) °C\nVlhkosť konštrukcie: \(proto.clima.humCon) %",
                                                 y: yForAntoherLine) + 10 // + padding
            yForAntoherLine += createRowOfThirds(bold: true, first: "Dátum realizácie skúšky:",
                                                 second: "Miesto a predmet skúšky:",
                                                 third: "Objednávateľ:",
                                                 y: yForAntoherLine)
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            let dateString = formatter.string(from: proto.creationDate ?? Date())
            
            yForAntoherLine += createRowOfThirds(first: dateString,
                                                 second: "\(proto.construction.address)\n\(proto.construction.section)",
                                                 third: "\(proto.client.name)\n\(proto.client.address)\nIČO: \(proto.client.ico)\n" + (proto.client.dic > 0 ? "DIČ: \(proto.client.dic)" : ""),
                                                 y: yForAntoherLine)
            if !proto.info.isEmpty && proto.info != "Popis / vyhodnotenie protokolu" {
                yForAntoherLine += addText(startAt: 30, y: yForAntoherLine, width: colWidth, aligment: .left, bold: true, body: "Vyhodnotenie:")
                yForAntoherLine += addText(startAt: 40, y: yForAntoherLine, width: colWidth * 3, aligment: .left, bold: false, body: "\(proto.info)")
            }
            
            yForAntoherLine += 30 // + padding before table
            
            var yRow = tableRowTitle(pageRect, y: yForAntoherLine)

            for photo in photos.sorted(by: { $0.name < $1.name }) {
                yRow += tableRow(y: yRow, photoID: photo.name, targetDiameter: photo.targetDiameter, description: photo.descriptionOfPlace, requestVal: proto.method.requestedValue, realVal: photo.value, dimension: proto.device.dimension)
            }
        }
        
    }
    
    func tableRow(y: CGFloat, photoID: Int16, targetDiameter: Double, description: String, requestVal: Double, realVal: Double, dimension: Dimensions) -> CGFloat{
        let width = (pageRect.width - 20) / 6
        let first = addText(startAt: 10, y: y, width: width, body: String(photoID))
        let second = addText(startAt: width, y: y, width: width, body: String(targetDiameter) + " mm")
        let third = addText(startAt: 2*width, y: y, width: width, body: description)
        let fourth = addText(startAt: 3*width, y: y, width: width, body: String(requestVal) + " \(dimension.rawValue)")
        let fifth = addText(startAt: 4*width, y: y, width: width, body: String(realVal) + " \(dimension.rawValue)")
        let sixth = addText(startAt: 5*width, y: y, width: width, body: realVal > requestVal ? "Vyhovuje" : "Nevyhovuje")
        return max(first, second, third, fourth, fifth, sixth)
        
    }
    
    private func createTitle(center: CGFloat, bottom: CGFloat) {
        guard let creator = UserDefaults.standard.creator else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let titleAttributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)
        ]
        let title = "\(creator.name), \(creator.address)\nIČO: \(creator.ico)"
        let formattedTitle = NSMutableAttributedString(string: title, attributes: titleAttributes)
        
        let titleStringRect = CGRect(
            x: pageRect.width * 0.2, // start at max logo end
            y: center,
            width: pageRect.width * 0.57, // create rect for max size of title
            height: bottom
        )
        
        formattedTitle.draw(in: titleStringRect)
    }
    
    private func addLogo() -> (bottom: CGFloat, center: CGFloat) {
        let maxHeight = pageRect.height * 0.1
        let maxWidth = pageRect.width * 0.2
        
        guard let image = UserDefaults.standard.logo else { return (maxHeight, maxHeight / 2)}
        
        let aspectWidth = maxWidth / image.size.width
        let aspectHeight = maxHeight / image.size.height
        let aspectRatio = min(aspectWidth, aspectHeight)
        
        let scaledWidth = image.size.width * aspectRatio
        let scaledHeight = image.size.height * aspectRatio
        
        let imageRect = CGRect(x: 20, y: 15, width: scaledWidth, height: scaledHeight)
        
        image.draw(in: imageRect)
        
        let bottom = image.size.height < maxHeight ? image.size.height : maxHeight
        let center = bottom / 2
        return (bottom: bottom, center: center)
    }
    
    private func createRowOfThirds(bold: Bool = false, first: String, second: String, third: String, y: CGFloat) -> CGFloat {
        // first col start at 10 (padding)
        let firstThird = addText(startAt: 10, y: y, width: colWidth - 10, bold: bold, body: first)
        // second col start at end of width of first col
        let secondThird = addText(startAt: colWidth, y: y, width: colWidth, bold: bold, body: second)
        // third col start at end of width of second col
        let thirdThird = addText(startAt: 2 * colWidth, y: y, width: colWidth, bold: bold, body: third)
        
        // return biggest y (the lowest point of rectangles)
        return max(firstThird, secondThird, thirdThird)
    }
    
    private func addText(startAt x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat = 0, aligment: NSTextAlignment = .center, bold: Bool = false, body: String) -> CGFloat {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = aligment
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        let bodyAttributes: [NSAttributedString.Key: NSObject]
        if bold {
            bodyAttributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 9)
            ]
        } else {
            bodyAttributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 9)
            ]
        }
        
        let formattedBody = NSMutableAttributedString(string: body, attributes: bodyAttributes)
        
        
        let h: CGFloat
        
        // if height is not set compute height of text
        if height == 0 {
            // if string is bigger than rectangle
            if formattedBody.size().width > width {
                let j = formattedBody.size().width / width
                h = formattedBody.size().height * j.rounded(.up)
            } else {
                h = formattedBody.size().height
            }
        } else {
           h = height
        }
        
        let bodyStringRect = CGRect(
            x: x,
            y: y,
            width: width,
            height: h
        )
        
        formattedBody.draw(in: bodyStringRect)
        return h // return the bottom of the line
    }
    
    private func tableRowTitle(_ pageRect: CGRect, y: CGFloat) -> CGFloat {
        // 20 padding from both sides, 6 cols
        let width = (pageRect.width - 20) / 6
        let Titles: [String] = ["Označenie meraného miesta", "Priemer terča", "Popis meraného miesta", "Požadovaná hodnota", "Nameraná hodnota", "Celkové hodnotenie"]
        var pom: CGFloat = 0.0
        var bottom: CGFloat = 0.0
        
        for title in Titles {
            let x: CGFloat
            if pom == 0{
                x = addText(startAt: 10, y: y, width: width, bold: true, body: title)
            }
            else{
                x = addText(startAt: width * pom, y: y, width: width, bold: true, body: title)
            }
            bottom = bottom > x ? bottom : x // find which col is "biggest"
            pom+=1
        }
        return bottom + y
    }
}
