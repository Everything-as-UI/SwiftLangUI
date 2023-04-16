//
//  Environment.swift
//  
//
//  Created by Denis Koryttsev on 11.03.23.
//

import CoreUI
import DocumentUI

extension TextDocument {
    public var erased: AnyTextDocument { AnyTextDocument(self) }
}

private enum IndentationKey: EnvironmentKey {
    static let defaultValue: Int = 4
}

extension EnvironmentValues {
    public var indentation: Int {
        get { self[IndentationKey.self] }
        set { self[IndentationKey.self] = newValue }
    }
}

// MARK: Implementation resolver

public struct ImplementationEnvironment {
    private var storage: [ObjectIdentifier: Any]

    public init() {
        self.storage = [:]
    }
    public init<T>(_ object: T) {
        self.storage = [ObjectIdentifier(T.self): object]
    }

    public subscript<Value>(valueType: Value.Type) -> Value? {
        set { storage[ObjectIdentifier(valueType)] = newValue }
        get {
            storage[ObjectIdentifier(valueType)].map { $0 as! Value }
        }
    }
}

public struct ImplementationIdentifier: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
}

public struct ImplementationResolverContext {
    public let identifier: ImplementationIdentifier
    public let environment: ImplementationEnvironment

    public init(_ identifier: ImplementationIdentifier, environment: ImplementationEnvironment) {
        self.identifier = identifier
        self.environment = environment
    }

    public static func context(_ identifier: ImplementationIdentifier) -> Self {
        Self(identifier, environment: ImplementationEnvironment())
    }
    public static func context<T>(_ identifier: ImplementationIdentifier, template: T) -> Self {
        Self(identifier, environment: ImplementationEnvironment(template))
    }
}

public protocol ImplementationResolver {
    var inheritedResolver: any ImplementationResolver { get }

    func combined(with other: any ImplementationResolver) -> Self

    func resolve(with context: ImplementationResolverContext) -> AnyTextDocument
    func resolve(for arg: ClosureDecl.Arg, with context: ImplementationResolverContext) -> AnyTextDocument
    func resolve(for variable: VarDecl, inExtension: Bool, mutable: Bool, with context: ImplementationResolverContext) -> AnyTextDocument
    func resolve(for function: Function, with context: ImplementationResolverContext) -> AnyTextDocument
    func resolve(for protocolDecl: ProtocolDecl, inExtension: Bool, with context: ImplementationResolverContext) -> AnyTextDocument
}
extension ImplementationResolver {
    public var inheritedResolver: any ImplementationResolver { `super` }
    public var `super`: any ImplementationResolver { ImplementationResolverKey.defaultValue }

    public func combined(with other: any ImplementationResolver) -> Self { self }

    public func resolve(with context: ImplementationResolverContext) -> AnyTextDocument {
        inheritedResolver.resolve(with: context)
    }
    public func resolve(for arg: ClosureDecl.Arg, with context: ImplementationResolverContext) -> AnyTextDocument {
        inheritedResolver.resolve(for: arg, with: context)
    }
    public func resolve(for variable: VarDecl, inExtension: Bool, mutable: Bool, with context: ImplementationResolverContext) -> AnyTextDocument {
        inheritedResolver.resolve(for: variable, inExtension: inExtension, mutable: mutable, with: context)
    }
    public func resolve(for function: Function, with context: ImplementationResolverContext) -> AnyTextDocument {
        inheritedResolver.resolve(for: function, with: context)
    }
    public func resolve(for protocolDecl: ProtocolDecl, inExtension: Bool, with context: ImplementationResolverContext) -> AnyTextDocument {
        Group {
            ForEach(protocolDecl.vars, separator: .newline) {
                resolve(for: $0.decl, inExtension: inExtension, mutable: $0.mutable, with: context)
            }
            ForEach(protocolDecl.funcs, separator: .newline) { $0.implementation(context) }
                .startingWithNewline(protocolDecl.vars.isEmpty ? 0 : 2)
        }.erased
    }
}
public struct DefaultImplementationResolver: ImplementationResolver {
    public let inheritedResolver: ImplementationResolver?

    @Environment(\.indentation) private var indentation

    init(inheritedResolver: ImplementationResolver) {
        self.inheritedResolver = inheritedResolver
    }

    public init() {
        self.inheritedResolver = nil
    }

    public func combined(with other: ImplementationResolver) -> DefaultImplementationResolver {
        Self(inheritedResolver: other)
    }

    public func resolve(with context: ImplementationResolverContext) -> AnyTextDocument {
        inheritedResolver?.resolve(with: context) ?? NullDocument().erased
    }
    public func resolve(for arg: ClosureDecl.Arg, with _: ImplementationResolverContext) -> AnyTextDocument {
        (arg.type + "()").erased
    }
    public func resolve(for variable: VarDecl, inExtension: Bool, mutable: Bool, with _: ImplementationResolverContext) -> AnyTextDocument {
        guard inExtension else {
            return Group {
                variable.appendingModifiers(mutable ? [.var] : [.let])
                variable.type.map { type in
                    Group {
                        " = "
                        type
                        Parenthesis.round
                    }
                }
            }.erased
        }
        return Group {
            variable.appendingModifiers([.var])
            Brackets(parenthesis: .curve.prefixed(.space), indentation: indentation) {
                if mutable {
                    """
                    get { fatalError(\"unimplemented\") }
                    set {}
                    """
                } else {
                    "fatalError(\"unimplemented\")"
                }
            }
        }.erased
    }
    public func resolve(for function: Function, with _: ImplementationResolverContext) -> AnyTextDocument {
        guard function.decl.result != nil else { return NullDocument().erased }
        return AnyTextDocument("fatalError(\"unimplemented\")")
    }
}

struct ImplementationResolverWrapper: ImplementationResolver, Combinable {
    var inheritedResolver: any ImplementationResolver { wrappedResolver }
    let wrappedResolver: any ImplementationResolver

    init(_ wrapped: any ImplementationResolver) {
        self.wrappedResolver = wrapped
    }

    func combined(with other: ImplementationResolverWrapper) -> ImplementationResolverWrapper {
        ImplementationResolverWrapper(wrappedResolver.combined(with: other.wrappedResolver))
    }

    func resolve(for protocolDecl: ProtocolDecl, inExtension: Bool, with context: ImplementationResolverContext) -> AnyTextDocument {
        wrappedResolver.resolve(for: protocolDecl, inExtension: inExtension, with: context)
    }
}

private enum ImplementationResolverKey: InheritableEnvironmentKey {
    static let defaultValue: ImplementationResolverWrapper = ImplementationResolverWrapper(DefaultImplementationResolver())
}

extension EnvironmentValues {
    public var implementationResolver: any ImplementationResolver {
        get { self[ImplementationResolverKey.self] }
        set { self[ImplementationResolverKey.self] = ImplementationResolverWrapper(newValue) }
    }
}

extension TextDocument {
    public func implementationResolver(_ value: any ImplementationResolver) -> some TextDocument {
        environment(\.implementationResolver, value)
    }
}
