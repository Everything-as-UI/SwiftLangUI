//
//  SwiftFile.swift
//  
//
//  Created by Denis Koryttsev on 22.07.23.
//

import Foundation
import DocumentUI

public struct SwiftFile<Content: TextDocument>: TextDocument {
    let header: String?
    let imports: [String]
    let content: Content

    public init(header: String? = nil, imports: String..., @TextDocumentBuilder content: @escaping () -> Content) {
        self.header = header
        self.imports = imports
        self.content = content()
    }

    public init(header: String? = nil, imports: String..., content: Content) {
        self.header = header
        self.imports = imports
        self.content = content
    }

    public var textBody: some TextDocument {
        header.endingWithNewline(1)
        ForEach(imports, separator: .newline) { moduleName in
            "import \(moduleName)"
        }.endingWithNewline(2)
        content
    }
}
