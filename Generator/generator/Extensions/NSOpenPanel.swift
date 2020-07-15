//
//  NSOpenPanel.swift
//  generator
//
//  Created by Vlad Z. on 7/14/20.
//

import AppKit

extension NSOpenPanel {
    static func openImage(completion: @escaping (_ result: Result<NSImage, Error>) -> ()) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["jpg",
                                  "jpeg",
                                  "png",
                                  "heic"]
        panel.canChooseFiles = true
        panel.begin { (result) in
            guard result == .OK,
                  let url = panel.urls.first,
                  let image = NSImage(contentsOf: url) else {
                completion(.failure(
                    NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get file location"])
                ))
                return
            }
            completion(.success(image))
        }
    }
}
