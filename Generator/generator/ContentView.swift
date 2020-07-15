//
//  ContentView.swift
//  generator
//
//  Created by Vlad Z. on 7/14/20.
//

import SwiftUI
import CoreGraphics

struct ContentView: View {
    @Binding
    var image: NSImage?

    @State
    var isHovering: Bool

    var body: some View {
        VStack(spacing: 15) {
            VStack {
                Text("PNG, JPG, JPEG, HEIC")
                Button(action: selectFile) {
                    Text("From Finder")
                }
            }
            InputImageView(image: self.$image)
                .onHover { hovering in
                    isHovering = hovering
                }
                .background(isHovering ? Color.gray : Color.black)
                .cornerRadius(8)
                .onTapGesture { selectFile() }
        }.padding(.all, 20)
    }

    private func selectFile() {
        NSOpenPanel.openImage { (result) in
            if case let .success(image) = result {
                self.image = image
            }
        }
    }

    init() {
        self._image = .constant(nil)
        self._isHovering = .init(initialValue: false)
    }
}

struct InputImageView: View {
    @Binding var image: NSImage?

    var body: some View {
        ZStack {
            if self.image != nil {
                Image(nsImage: self.image!)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("Drag and drop image file")
                    .frame(width: 320)
            }
        }
        .frame(height: 320)
        .onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
            if let item = items.first {
                if let identifier = item.registeredTypeIdentifiers.first {
                    print("onDrop with identifier = \(identifier)")
                    if identifier == "public.url" || identifier == "public.file-url" {
                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                            DispatchQueue.main.async {
                                if let urlData = urlData as? Data {
                                    let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                    if let img = NSImage(contentsOf: urll) {
                                        self.image = img
                                        guard img.size.height < 80,
                                              img.size.width < 80 else { return }

                                        let imageRef = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
                                        let bitmap = Bitmap(from: imageRef!)

                                        (0..<bitmap.width).forEach { i in
                                            (0..<bitmap.height).forEach { j in
                                                let nanogramCheck = bitmap[i, j].alpha != 0
                                                print("[\(i); \(j)]: \(nanogramCheck)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                return true
            } else {
                print("item not here")
                return false }
        }
    }
}
