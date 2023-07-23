//
//  Closure.swift
//  
//
//  Created by Denis Koryttsev on 23.07.23.
//

import CoreUI
import DocumentUI

public struct ClosureDecl: TextDocument {
    public let name: String?
    public let args: [Arg]
    public let result: String?
    public let generics: [Generic]
    public let modifiers: [Keyword]
    public let traits: [Keyword]
    public let attributes: [String]

    public init(name: String? = nil, args: [Arg] = [], result: String? = nil, generics: [Generic] = [], modifiers: [Keyword] = [], traits: [Keyword] = [], attributes: [String] = []) {
        self.name = name
        self.args = args
        self.result = result
        self.generics = generics
        self.modifiers = modifiers
        self.traits = traits
        self.attributes = attributes
    }

    public var textBody: some TextDocument {
        ForEach(attributes, separator: .newline, content: { "@\($0)" }).endingWithNewline()
        ForEach(modifiers, separator: .space, content: { $0 }).suffix(String.space)
        name
        ForEach(generics, separator: .commaSpace, content: { $0 })
            .parenthical(.triangular)
        Brackets(parenthesis: .round) {
            ForEach(args, separator: .commaSpace, content: { $0 }) // TODO: add environment variable with style configuration
        }
        ForEach(traits, separator: .space, content: { $0 }).prefix(String.space)
        result.prefix(String.space + .arrow + .space)
    }

    public struct Arg: TextDocument {
        public let label: String
        public let type: String // TODO: add enum with case closure(ClosureDecl)
        public let argName: String?
        public let defaultValue: String?
        public let attributes: [String]

        public init(label: String = "_", type: String, argName: String? = nil, defaultValue: String? = nil, attributes: [String] = []) {
            self.label = label
            self.type = type
            self.argName = argName
            self.defaultValue = defaultValue
            self.attributes = attributes
        }

        public var textBody: some TextDocument {
            Joined(separator: " ", elements: attributes).suffix(" ")
            ForEach([label, argName], separator: " ", content: { $0 })
            type.prefix(": ")
            defaultValue.prefix(" = ")
        }

        @Environment(\.implementationResolver) private var implementationResolver
    }
}
extension ClosureDecl.Arg {
    public var name: String { argName ?? label }

    @TextDocumentBuilder
    public func implementation(_ context: ImplementationResolverContext) -> some TextDocument {
        if label != "_" {
            label + ": "
        }
        implementationResolver.resolve(for: self, with: context)
    }
}
extension ClosureDecl {
    func withName(_ name: String) -> Self {
        Self(name: name, args: args, result: result, generics: generics, modifiers: modifiers, traits: traits, attributes: attributes)
    }
    func withModifiers(_ modifiers: [Keyword]) -> Self {
        Self(name: name, args: args, result: result, generics: generics, modifiers: modifiers, traits: traits, attributes: attributes)
    }
}
