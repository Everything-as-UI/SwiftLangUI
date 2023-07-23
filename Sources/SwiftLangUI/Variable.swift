//
//  Variable.swift
//  
//
//  Created by Denis Koryttsev on 23.07.23.
//

import CoreUI
import DocumentUI

public struct VarDecl: TextDocument {
    public let name: String
    public let type: String?
    public let modifiers: [Keyword]
    public let attributes: [String]

    public init(name: String, type: String? = nil, modifiers: [Keyword] = [], attributes: [String] = []) {
        self.name = name
        self.type = type
        self.modifiers = modifiers
        self.attributes = attributes
    }

    public var textBody: some TextDocument {
        ForEach(attributes, separator: "\n", content: { "@\($0)" }).suffix("\n")
        ForEach(modifiers, separator: " ", content: { $0 }).suffix(" ")
        name
        type.prefix(": ")
    }

    @Environment(\.implementationResolver) private var implementationResolver
}
extension VarDecl {
    @TextDocumentBuilder
    public func implementation(inExtension: Bool, mutable: Bool, context: ImplementationResolverContext) -> some TextDocument {
        implementationResolver.resolve(for: self, inExtension: inExtension, mutable: mutable, with: context)
    }
}
extension VarDecl {
    public func withModifiers(_ modifiers: [Keyword]) -> Self {
        Self(name: name, type: type, modifiers: modifiers, attributes: attributes)
    }
    public func prependingModifiers(_ modifiers: [Keyword]) -> Self {
        Self(name: name, type: type, modifiers: modifiers + self.modifiers, attributes: attributes)
    }
    public func appendingModifiers(_ modifiers: [Keyword]) -> Self {
        Self(name: name, type: type, modifiers: self.modifiers + modifiers, attributes: attributes)
    }
}
