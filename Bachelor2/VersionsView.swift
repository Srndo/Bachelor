//
//  VersionsView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 02/04/2021.
//

import SwiftUI

struct VersionsView: View {
    @State private var show: Bool = false
    @State private var toShow: OutputArchive? = nil
    @Binding var message: String
    private var versions: [OutputArchive] = []
    private var protoID: Int
    
    init(protoID: Int, versions: [OutputArchive], message: Binding<String>) {
        self.protoID = protoID
        self.versions = versions.sorted(by: { $0.internalID > $1.internalID })
        _message = message
    }
    
    var body: some View {
        List {
            ForEach(versions, id:\.self) { version in
                ZStack{
                    NavigationLink(destination: PDF().showPDF(version: version)){
                        EmptyView()
                    }
                    .hidden()
                    HStack{
                        Text("\(version.internalID)")
                        if version.pdf {
                            Spacer()
                            Text("protokol.pdf")
                        }
                        if version.zip {
                            Spacer()
                            Text("fotky.zip")
                        }
                        Spacer()
                        Spacer()
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.blue)
                            .onTapGesture {
                                var items: [Any] = []
                                if version.pdf {
                                    guard let pdfURL = Dirs.shared.getPdfURL(protoID: Int(version.protoID), internalID: Int(version.internalID)) else { return }
                                    items.append(pdfURL)
                                }
                                if version.zip {
                                    guard let zipURL = Dirs.shared.getZipURL(protoID: Int(version.protoID), internalID: Int(version.internalID)) else { return }
                                    items.append(zipURL)
                                }
                                
                                if share(items: items) {
                                    message = "Súbory možné odoslať"
                                } else {
                                    message = "ERROR: Súbory sa nepodarilo odoslať"
                                }
                        }
                    }
                }
            }
        }
        .onAppear{
            toShow = versions.first
        }
        .onDisappear{
            message = ""
        }
    }
    
    private func share(items: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) -> Bool {
        guard let source = UIApplication.shared.windows.last?.rootViewController else {
            return false
        }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.excludedActivityTypes = excludedActivityTypes
        vc.popoverPresentationController?.sourceView = source.view
        source.present(vc, animated: true)
        return true
    }
}
