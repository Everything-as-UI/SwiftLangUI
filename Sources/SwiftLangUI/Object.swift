//
//  Object.swift
//  
//
//  Created by Denis Koryttsev on 23.07.23.
//

import DocumentUI

public struct ObjectType: TextDocument {
    public let decl: TypeDecl
    public let properties: [Variable]
    public let functions: [Function]

    init(name: String, inherits: [String], properties: [Variable] = [], functions: [Function] = [], modifiers: [Keyword] = [], generics: [Generic] = [], attributes: [String] = []) {
        self.decl = TypeDecl(name: name, modifiers: modifiers, inherits: inherits, generics: generics, attributes: attributes)
        self.properties = properties
        self.functions = functions
    }

    public static func `struct`(name: String, inherits: [String] = [], properties: [Variable] = [], functions: [Function] = [], modifiers: [Keyword] = [], generics: [Generic] = [], attributes: [String] = []) -> Self {
        Self(name: name, inherits: inherits, properties: properties, functions: functions, modifiers: modifiers + [.struct], generics: generics, attributes: attributes)
    }

    public static func `class`(name: String, inherits: [String] = [], properties: [Variable] = [], functions: [Function] = [], modifiers: [Keyword] = [], generics: [Generic] = [], attributes: [String] = []) -> Self {
        Self(name: name, inherits: inherits, properties: properties, functions: functions, modifiers: modifiers + [.class], generics: generics, attributes: attributes)
    }

    public var textBody: some TextDocument {
        decl.withBody {
            Joined(separator: String.newline, elements: properties)
            Joined(separator: String.newline + .newline, elements: functions).startingWithNewline(properties.isEmpty ? 0 : 2)
        }
    }
}

/*
public struct ObjectType2: TextDocument {
    public let decl: TypeDecl
    let body: AnyTextDocument

    init(name: String, inherits: [String], modifiers: [Keyword] = [], generics: [Generic] = [], attributes: [String] = [], body: AnyTextDocument) {
        self.decl = TypeDecl(name: name, modifiers: modifiers, inherits: inherits, generics: generics, attributes: attributes)
        self.body = body
    }

    public static func `struct`(name: String, inherits: [String] = [], properties: [Variable] = [], functions: [Function] = [], modifiers: [Keyword] = [], generics: [Generic] = [], attributes: [String] = []) -> Self {
        Self(name: name, inherits: inherits, modifiers: modifiers + [.struct], generics: generics, attributes: attributes, body: Group {
            Joined(separator: String.newline, elements: properties)
            Joined(separator: String.newline + .newline, elements: functions).startingWithNewline(properties.isEmpty ? 0 : 2)
        }.erased)
    }

    public static func `class`(name: String, inherits: [String] = [], properties: [Variable] = [], functions: [Function] = [], modifiers: [Keyword] = [], generics: [Generic] = [], attributes: [String] = []) -> Self {
        Self(name: name, inherits: inherits, modifiers: modifiers + [.class], generics: generics, attributes: attributes, body: Group {
            Joined(separator: String.newline, elements: properties)
            Joined(separator: String.newline + .newline, elements: functions).startingWithNewline(properties.isEmpty ? 0 : 2)
        }.erased)
    }

    public var textBody: some TextDocument {
        decl.withBody {
            body
        }
    }
}
*/
