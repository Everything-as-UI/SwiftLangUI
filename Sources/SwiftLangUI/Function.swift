//
//  Function.swift
//  
//
//  Created by Denis Koryttsev on 23.07.23.
//

import CoreUI
import DocumentUI

public struct Function: TextDocument {
    public let decl: ClosureDecl

    init(decl: ClosureDecl) {
        self.decl = decl
    }

    public init(name: String, args: [ClosureDecl.Arg] = [], result: String? = nil, generics: [Generic] = [], modifiers: [Keyword] = [], traits: [Keyword] = [], attributes: [String] = []) {
        self.decl = ClosureDecl(name: name, args: args, result: result, generics: generics, modifiers: modifiers + [.func], traits: traits, attributes: attributes)
    }

    public var textBody: some TextDocument {
        decl
    }

    @Environment(\.implementationResolver) private var implementationResolver
}
extension Function {
    @TextDocumentBuilder
    public func implementation(_ context: ImplementationResolverContext) -> some TextDocument {
        DeclWithBody(decl: self) {
            implementationResolver.resolve(for: self, with: context)
        }
    }

    @TextDocumentBuilder
    public func call(in instance: String?, with context: ImplementationResolverContext = .context("")) -> some TextDocument {
        instance.suffix(String.dot)
        decl.name
        Brackets(parenthesis: .round) {
            Joined(separator: String.commaSpace, elements: decl.args.map { $0.implementation(context) })
        }
    }

    @TextDocumentBuilder
    public func args(with context: ImplementationResolverContext = .context("")) -> some TextDocument {
        Joined(separator: String.commaSpace, elements: decl.args.map { $0.implementation(context) })
    }
}
extension Function {
    public func withName(_ name: String) -> Self {
        Self(decl: decl.withName(name))
    }
    public func withModifiers(_ modifiers: [Keyword]) -> Self {
        Self(decl: decl.withModifiers(modifiers + [.func]))
    }
}
