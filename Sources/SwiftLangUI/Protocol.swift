//
//  Protocol.swift
//  
//
//  Created by Denis Koryttsev on 23.07.23.
//

import CoreUI
import DocumentUI

public struct ProtocolDecl: TextDocument {
    public let decl: TypeDecl
    public let vars: [Var]
    public let funcs: [ClosureDecl]
    public let associatedTypes: [AssociatedType]

    public init(name: String, vars: [Var] = [], funcs: [ClosureDecl] = [], associatedTypes: [AssociatedType] = [], modifiers: [Keyword] = [],
                inherits: [String] = [], generics: [Generic] = [], attributes: [String] = []) {
        self.decl = TypeDecl(name: name, modifiers: modifiers + [.protocol], inherits: inherits, generics: generics, attributes: attributes)
        self.vars = vars
        self.funcs = funcs
        self.associatedTypes = associatedTypes
    }

    @Environment(\.indentation) private var indentation
    @Environment(\.implementationResolver) private var implementationResolver

    public var textBody: some TextDocument {
        DeclWithBody(decl: decl) {
            Joined(separator: String.newline, elements: associatedTypes)
            Joined(separator: String.newline, elements: vars).startingWithNewline(associatedTypes.isEmpty ? 0 : 1)
            Joined(separator: String.newline, elements: funcs).startingWithNewline(vars.isEmpty ? 0 : 1)
        }
    }

    public struct Var: TextDocument {
        public let decl: VarDecl
        public let accessor: Accessor
        public var mutable: Bool {
            guard case .mutable = accessor else { return false }
            return true
        }

        public enum Accessor {
            case mutable
            case immutable(throwing: Bool = false, async: Bool = false)
        }

        public init(decl: VarDecl, accessor: Accessor) {
            self.decl = decl.withModifiers([])
            self.accessor = accessor
        }

        public init(name: String, type: String, attributes: [String] = [], accessor: Accessor = .immutable()) {
            self.decl = VarDecl(name: name, type: type, attributes: attributes)
            self.accessor = accessor
        }

        @Environment(\.implementationResolver) private var implementationResolver

        public var textBody: some TextDocument {
            decl.appendingModifiers([.var])
            switch accessor {
            case .mutable: " { get set }"
            case .immutable(let throwing, let async):
                " { get "
                if async {
                    "async "
                }
                if throwing {
                    "throws "
                }
                "}"
            }
        }
    }

    public struct AssociatedType: TextDocument {
        public let name: String
        public let inherits: String?

        public init(name: String, inherits: String? = nil) {
            self.name = name
            self.inherits = inherits
        }

        public var textBody: some TextDocument {
            "associatedtype \(name)"
            if let inherits {
                ": \(inherits)"
            }
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
