//
//  Type.swift
//  
//
//  Created by Denis Koryttsev on 23.07.23.
//

import DocumentUI

public struct TypeDecl: TextDocument {
    public let name: String
    public let modifiers: [Keyword]
    public let inherits: [String]
    public let generics: [Generic]
    public let attributes: [String]

    public init(name: String, modifiers: [Keyword] = [], inherits: [String] = [], generics: [Generic] = [], attributes: [String] = []) {
        self.name = name
        self.modifiers = modifiers
        self.inherits = inherits
        self.generics = generics
        self.attributes = attributes
    }

    public var textBody: some TextDocument {
        ForEach(attributes, separator: "\n", content: { "@\($0)" }).suffix("\n")
        ForEach(modifiers, separator: " ", content: { $0 }).suffix(" ")
        name
        ForEach(generics, separator: ", ", content: { $0 }).parenthical(.triangular)
        ForEach(inherits, separator: ", ", content: { $0 }).prefix(": ")
    }
}
extension TypeDecl {
    @TextDocumentBuilder
    public func callInit(args: [ClosureDecl.Arg], with context: ImplementationResolverContext = .context("")) -> some TextDocument {
        name
        Brackets(parenthesis: .round) {
            ForEach(args, separator: .commaSpace) { $0.implementation(context) }
        }
    }
}
