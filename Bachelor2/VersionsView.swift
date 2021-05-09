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
    private var versions: [OutputArchive] = []
    private var protoID: Int
    
    init(protoID: Int, versions: [OutputArchive]) {
        self.protoID = protoID
        self.versions = versions.sorted(by: { $0.internalID > $1.internalID })
//        _toShow = State(initialValue: self.versions.last)
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
                                toShow = version
                            }
                    }
                    .sheet(isPresented: $show) {
                        ActivityViewController(version: toShow)
                    }
                }
            }
        }
        .onChange(of: toShow) { _ in
            self.show.toggle()
        }
    }
    
    struct ActivityViewController: UIViewControllerRepresentable {
        
        var version: OutputArchive?
        var applicationActivities: [UIActivity]? = nil

        func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
            var items: [Any] = []
            guard let version = version else { return UIActivityViewController(activityItems: items, applicationActivities: applicationActivities) }
            if version.pdf {
                if let url = version.getPdfURL() {
                    items.append(url)
                }
            }
            if version.zip {
                if let url = version.getZipURL() {
                    items.append(url)
                }
            }
            let controller = UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
            return controller
        }

        func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}

    }
}
