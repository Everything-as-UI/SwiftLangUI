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

    public static func function(name: String, args: [Arg] = [], result: String? = nil, generics: [Generic] = [], modifiers: [Keyword] = [], traits: [Keyword] = [], attributes: [String] = []) -> Self {
        Self(name: name, args: args, result: result, generics: generics, modifiers: modifiers + [.func], traits: traits, attributes: attributes)
    }

    public static func initializer(args: [Arg] = [], generics: [Generic] = [], modifiers: [Keyword] = [], traits: [Keyword] = [], attributes: [String] = []) -> Self {
        Self(name: "init", args: args, generics: generics, modifiers: modifiers, traits: traits, attributes: attributes)
    }

    @Environment(\.codeStyle) private var codeStyle
    @Environment(\.indentation) private var indentation
    @Environment(\.implementationResolver) private var implementationResolver

    public var textBody: some TextDocument {
        if let name {
            ForEach(attributes, separator: .newline, content: { "@\($0)" }).endingWithNewline()
            ForEach(modifiers, separator: .space, content: { $0 }).suffix(String.space)
            name
            ForEach(generics, separator: .commaSpace, content: { $0 })
                .parenthical(.triangular)
        }
        Brackets(parenthesis: .round, indentation: exceededMaxArgs ? indentation : nil) {
            ForEach(args, separator: exceededMaxArgs ? .comma + .newline : .commaSpace, content: { $0 })
        }
        ForEach(traits, separator: .space, content: { $0 }).prefix(String.space)
        result.prefix(String.space + .arrow + .space)
    }

    private var exceededMaxArgs: Bool {
        codeStyle.maxArgsInSingleLine.map { $0 < args.count } ?? false
    }
}

extension ClosureDecl {
    public struct Arg: TextDocument {
        public let label: String?
        public let type: String // TODO: add enum with case closure(ClosureDecl)
        public let argName: String?
        public let defaultValue: String?
        public let attributes: [String]

        public init(label: String? = "_", type: String, argName: String? = nil, defaultValue: String? = nil, attributes: [String] = []) {
            self.label = label
            self.type = type
            self.argName = argName
            self.defaultValue = defaultValue
            self.attributes = attributes
        }

        public var textBody: some TextDocument {
            Joined(separator: " ", elements: attributes).suffix(" ")
            ForEach([label, argName].compactMap { $0 }, separator: " ", content: { $0 }).suffix(": ")
            type
            defaultValue.prefix(" = ")
        }

        @Environment(\.implementationResolver) private var implementationResolver
    }
}
extension ClosureDecl.Arg {
    public var name: String? { argName ?? label }

    @TextDocumentBuilder
    public func implementation(_ context: ImplementationResolverContext) -> some TextDocument {
        if let label, label != "_" {
            label + ": "
        }
        implementationResolver.resolve(for: self, with: context)
    }
}
extension ClosureDecl {
    public func withName(_ name: String) -> Self {
        Self(name: name, args: args, result: result, generics: generics, modifiers: modifiers, traits: traits, attributes: attributes)
    }
    public func withModifiers(_ modifiers: [Keyword]) -> Self {
        Self(name: name, args: args, result: result, generics: generics, modifiers: modifiers, traits: traits, attributes: attributes)
    }
}
extension ClosureDecl {
    @TextDocumentBuilder
    public func implementation(_ context: ImplementationResolverContext) -> some TextDocument {
        DeclWithBody(decl: self) {
            implementationResolver.resolve(for: self, with: context)
        }
    }

    @TextDocumentBuilder
    public func call(in instance: String?, with context: ImplementationResolverContext = .context("")) -> some TextDocument {
        instance.suffix(String.dot)
        name
        Brackets(parenthesis: .round) {
            Joined(separator: String.commaSpace, elements: args.map { $0.implementation(context) })
        }
    }

    @TextDocumentBuilder
    public func args(with context: ImplementationResolverContext = .context("")) -> some TextDocument {
        Joined(separator: String.commaSpace, elements: args.map { $0.implementation(context) })
    }
}
