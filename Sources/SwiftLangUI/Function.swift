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
    public let body: AnyTextDocument

    init(decl: ClosureDecl, body: AnyTextDocument) {
        self.decl = decl
        self.body = body
    }

    public init<Body: TextDocument>(decl: ClosureDecl, @TextDocumentBuilder body: () -> Body) {
        assert(decl.modifiers.contains(.func))
        self.decl = decl
        self.body = body().erased
    }

    public init<Body: TextDocument>(name: String, args: [ClosureDecl.Arg] = [], result: String? = nil, generics: [Generic] = [], modifiers: [Keyword] = [], traits: [Keyword] = [], attributes: [String] = [], @TextDocumentBuilder body: () -> Body) {
        self.decl = ClosureDecl(name: name, args: args, result: result, generics: generics, modifiers: modifiers + [.func], traits: traits, attributes: attributes)
        self.body = body().erased
    }

    public static func initializer<Body: TextDocument>(optional: Bool = false, args: [ClosureDecl.Arg] = [], generics: [Generic] = [], modifiers: [Keyword] = [], traits: [Keyword] = [], attributes: [String] = [], @TextDocumentBuilder body: () -> Body) -> Self {
        Self.init(decl: ClosureDecl(name: "init" + (optional ? "?" : ""), args: args, generics: generics, modifiers: modifiers, traits: traits, attributes: attributes), body: body().erased)
    }

    public var textBody: some TextDocument {
        decl.withBody {
            body
        }
    }

    @Environment(\.implementationResolver) private var implementationResolver
}
extension Function {
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
        Self(decl: decl.withName(name), body: body)
    }
    public func withModifiers(_ modifiers: [Keyword]) -> Self {
        Self(decl: decl.withModifiers(modifiers + [.func]), body: body)
    }
}
