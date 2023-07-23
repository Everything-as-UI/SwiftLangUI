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

    init(name: String, inherits: [String], modifiers: [Keyword] = [], properties: [Variable] = [], functions: [Function] = []) {
        self.decl = TypeDecl(name: name, modifiers: modifiers, inherits: inherits)
        self.properties = properties
        self.functions = functions
    }

    public static func `struct`(name: String, inherits: [String] = [], modifiers: [Keyword] = [], properties: [Variable] = [], functions: [Function] = []) -> Self {
        Self(name: name, inherits: inherits, modifiers: modifiers + [.struct], properties: properties, functions: functions)
    }

    public static func `class`(name: String, inherits: [String] = [], modifiers: [Keyword] = [], properties: [Variable] = [], functions: [Function] = []) -> Self {
        Self(name: name, inherits: inherits, modifiers: modifiers + [.class], properties: properties, functions: functions)
    }

    public var textBody: some TextDocument {
        decl.withBody {
            Joined(separator: String.newline, elements: properties)
            Joined(separator: String.newline + .newline, elements: functions).startingWithNewline(properties.isEmpty ? 0 : 2)
        }
    }
}
