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

public struct Variable: TextDocument {
    public let decl: VarDecl
    public let mutable: Bool
    public let body: Body

    public init(decl: VarDecl, mutable: Bool = false, body: Body) {
        self.decl = decl
        self.mutable = mutable
        self.body = body
    }

    public init(name: String, type: String, modifiers: [Keyword] = [], attributes: [String] = [], mutable: Bool = false, body: Body) {
        self.decl = VarDecl(name: name, type: type, modifiers: modifiers, attributes: attributes)
        self.mutable = mutable
        self.body = body
    }

    public var textBody: some TextDocument {
        decl.appendingModifiers(mutable || body.isComputed || decl.modifiers.contains(.weak) ? [.var] : [.let])
        body
    }

    public enum Body: TextDocument {
        case empty
        case value(AnyTextDocument)
        case computed(ComputedBody)

        var isComputed: Bool {
            guard case .computed = self else { return false }
            return true
        }

        public var textBody: some TextDocument {
            switch self {
            case .empty: NullDocument()
            case .value(let value): " = \(value)"
            case .computed(let body): body
            }
        }
    }

    public struct ComputedBody: TextDocument {
        let getter: AnyTextDocument
        let setter: AnyTextDocument?

        public init(getter: AnyTextDocument, setter: AnyTextDocument? = nil) {
            self.getter = getter
            self.setter = setter
        }

        @Environment(\.indentation) private var indentation

        public var textBody: some TextDocument {
            Brackets(parenthesis: .curve.prefixed(.space), indentation: indentation) {
                if let setter {
                    "get"
                    Brackets(parenthesis: .curve, indentation: indentation) {
                        getter
                    }.endingWithNewline()
                    "set"
                    Brackets(parenthesis: .curve, indentation: indentation) {
                        setter
                    }
                } else {
                    getter
                }
            }
        }
    }
}
