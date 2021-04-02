//
//  VersionsView.swift
//  Bachelor2
//
//  Created by Simon Sestak on 02/04/2021.
//

import SwiftUI

struct VersionsView: View {
    private var versions: [OutputArchive] = []
    private var protoID: Int
    
    init(protoID: Int, versions: [OutputArchive]) {
        self.protoID = protoID
        self.versions = versions.sorted(by: { $0.internalID > $1.internalID })
    }
    
    var body: some View {
        List {
            ForEach(versions, id:\.self) { version in
                HStack{
                    Text("\(version.internalID)")
                    if version.pdf {
                        Spacer()
                        Text("protokol.pdf").onTapGesture {
//                            showPDF()
                        }
                        
                    }
                    if version.zip {
                        Spacer()
                        Text("fotky.zip")
                    }
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.blue)
                        .onTapGesture {
                            // MARK: TODO
                            share(items: ["This is some text"])
                    }
                }
            }
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
