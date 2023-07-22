//
//  SwiftLang.swift
//
//
//  Created by Denis Koryttsev on 4.02.23.
//

import CoreUI
import DocumentUI

public enum Keyword: String { // TODO: separate to different enums
    case `class`, `enum`, `func`, `protocol`, `struct`, `typealias`, `extension`
    case `fileprivate`, `internal`, `private`, `public`, `open`
    case `let`, `var`
    case `lazy`, `static`, `weak`, `unowned`
    case `async`, `await`, `throws`, `rethrows`
    case `final`
    case propertyWrapper, main
}
extension Keyword: TextDocument {
    public var textBody: some TextDocument { rawValue }
}

public struct Comment {
    public enum CommentType {
        case line(documented: Bool)
        case block
        case newLineBlock
    }

    let type: CommentType
}
extension Comment: TextDocumentModifier {
    public func modify(content: inout String) {
        switch type {
        case .block:
            content = "/*" + content + "*/"
        case .newLineBlock:
            content = "/*\n" + content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .joined(separator: "\n")
            + "\n */"
        case .line(let documented):
            let prefix = documented ? "/// " : "// "
            content = content.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
                .lazy.map { prefix + $0 }
                .joined(separator: "\n")
        }
    }
}
extension TextDocument {
    public func commented(_ type: Comment.CommentType = .line(documented: false)) -> _ModifiedDocument<Self, Comment> {
        _ModifiedDocument(self, modifier: Comment(type: type))
    }
}

public struct BoundModifier: TextDocumentModifier {
    let open: String
    let close: String

    public func modify(content: inout String) {
        content = open + content + close
    }
}

extension TextDocument {
    public func bouned(open: String, close: String) -> _ModifiedDocument<Self, BoundModifier> {
        modifier(BoundModifier(open: open, close: close))
    }
    public func parenthical(_ parenthesis: Parenthesis) -> _ModifiedDocument<Self, BoundModifier> {
        modifier(BoundModifier(open: parenthesis.open, close: parenthesis.close))
    }
}

public struct Parenthesis {
    public let open: String
    public let close: String

    public static let curve = Self(open: "{", close: "}")
    public static let triangular = Self(open: "<", close: ">")
    public static let round = Self(open: "(", close: ")")
    public static let square = Self(open: "[", close: "]")

    public func prefixed(_ prefix: String) -> Self {
        Self(open: prefix + open, close: close)
    }
}
extension Parenthesis: TextDocument {
    public var textBody: some TextDocument {
        open
        close
    }
}

public struct Brackets<Content: TextDocument>: TextDocument { // TODO: Rename
    public let open: String
    public let close: String
    public let indentation: Int?
    @TextDocumentBuilder public let content: () -> Content

    public init(open: String, close: String, indentation: Int? = nil, @TextDocumentBuilder content: @escaping () -> Content) {
        self.open = open
        self.close = close
        self.indentation = indentation
        self.content = content
    }

    public init(parenthesis: Parenthesis, indentation: Int? = nil, @TextDocumentBuilder content: @escaping () -> Content) {
        self.open = parenthesis.open
        self.close = parenthesis.close
        self.indentation = indentation
        self.content = content
    }

    public var textBody: some TextDocument {
        open
        if let indentation {
            content().indent(indentation).prefix("\n").suffix("\n")
        } else {
            content()
        }
        close
    }
}

public struct Mark: TextDocument {
    let name: String

    public init(name: String) {
        self.name = name
    }

    public var textBody: some TextDocument {
        "// MARK: - "
        name
    }
}

public struct Todo: TextDocument {
    public let version: String
    public let author: String?
    public let text: String

    public init(version: String, author: String?, text: String) {
        self.version = version
        self.author = author
        self.text = text
    }

    public var textBody: some TextDocument {
        "// TODO: "
        Joined(separator: ", ", elements: [version, author, text])
    }
}

public struct Generic: TextDocument {
    public let name: String
    public let constraints: [String]

    public init(name: String, constraints: [String] = []) {
        self.name = name
        self.constraints = constraints
    }

    public var textBody: some TextDocument {
        name
        ForEach(constraints, separator: " & ", content: { $0 }).prefix(": ")
    }
}

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


public struct DeclWithBody<Decl, Body>: TextDocument where Decl: TextDocument, Body: TextDocument {
    public let decl: Decl
    @TextDocumentBuilder let body: () -> Body

    public init(decl: Decl, @TextDocumentBuilder body: @escaping () -> Body) {
        self.decl = decl
        self.body = body
    }

    @Environment(\.indentation) private var indentation

    public var textBody: some TextDocument {
        decl
        Brackets(parenthesis: .curve.prefixed(.space), indentation: indentation, content: body)
    }
}
extension TextDocument {
    func withBody<Body: TextDocument>(@TextDocumentBuilder _ body: @escaping () -> Body) -> some TextDocument {
        DeclWithBody(decl: self, body: body)
    }
}


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
        instance.suffix(".")
        decl.name
        Brackets(parenthesis: .round) {
            Joined(separator: ", ", elements: decl.args.map { $0.implementation(context) })
        }
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

public struct ProtocolDecl: TextDocument {
    public let decl: TypeDecl
    public let vars: [Var]
    public let funcs: [Function]

    public init(name: String, vars: [Var] = [], funcs: [Function] = [], modifiers: [Keyword] = [],
         inherits: [String] = [], generics: [Generic] = [], attributes: [String] = []) {
        self.decl = TypeDecl(name: name, modifiers: modifiers + [.protocol], inherits: inherits, generics: generics, attributes: attributes)
        self.vars = vars
        self.funcs = funcs
    }

    @Environment(\.indentation) private var indentation
    @Environment(\.implementationResolver) private var implementationResolver

    public var textBody: some TextDocument {
        DeclWithBody(decl: decl) {
            Joined(separator: String.newline, elements: vars)
            Joined(separator: String.newline, elements: funcs).startingWithNewline(vars.isEmpty ? 0 : 1)
        }
    }

    public struct Var: TextDocument {
        public let decl: VarDecl
        public let mutable: Bool

        public init(decl: VarDecl, mutable: Bool) {
            self.decl = decl
            self.mutable = mutable
        }

        public init(name: String, type: String, modifiers: [Keyword] = [], attributes: [String] = [], mutable: Bool = false) {
            self.decl = VarDecl(name: name, type: type, modifiers: modifiers, attributes: attributes)
            self.mutable = mutable
        }

        @Environment(\.implementationResolver) private var implementationResolver

        public var textBody: some TextDocument {
            decl.appendingModifiers([.var])
            mutable ? " { get set }" : " { get }"
        }
    }
}

extension ProtocolDecl.Var {
    @TextDocumentBuilder
    public func implementation(inExtension: Bool, with context: ImplementationResolverContext) -> some TextDocument {
        implementationResolver.resolve(for: decl, inExtension: inExtension, mutable: mutable, with: context)
    }
}

extension ProtocolDecl {
    @TextDocumentBuilder
    public func `extension`(type name: String? = nil, with context: ImplementationResolverContext) -> some TextDocument {
        TypeDecl(name: name ?? decl.name, modifiers: [.extension], inherits: name != nil ? [decl.name] : [])
        Brackets(parenthesis: .curve.prefixed(.space), indentation: indentation) {
            implementation(inExtension: true, with: context)
        }
    }

    @TextDocumentBuilder
    public func varsImplementation(inExtension: Bool, with context: ImplementationResolverContext) -> some TextDocument {
        ForEach(vars, separator: .newline) { $0.implementation(inExtension: inExtension, with: context) }
    }

    @TextDocumentBuilder
    public func funcsImplementation(with context: ImplementationResolverContext) -> some TextDocument {
        ForEach(funcs, separator: .newline) { $0.implementation(context) }
    }

    @TextDocumentBuilder
    public func implementation(inExtension: Bool, with context: ImplementationResolverContext) -> some TextDocument {
        implementationResolver.resolve(for: self, inExtension: inExtension, with: context)
    }
}
