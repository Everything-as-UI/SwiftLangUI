//
//  Enum.swift
//  
//
//  Created by Denis Koryttsev on 23.07.23.
//

import DocumentUI

public struct Enum: TextDocument {
    public let decl: TypeDecl
    public let cases: [Case]

    public init(typeName: String, inherits: [String] = [], modifiers: [Keyword] = [], cases: [Case]) {
        self.decl = TypeDecl(name: typeName, modifiers: modifiers + [.enum], inherits: inherits)
        self.cases = cases
    }

    public var textBody: some TextDocument {
        decl.withBody {
            Joined(separator: String.newline, elements: cases)
        }
    }

    public struct Case: TextDocument {
        public let name: String
        public let associatedTypes: [ClosureDecl.Arg]
        public let indirect: Bool

        public init(name: String, associatedTypes: [ClosureDecl.Arg] = [], indirect: Bool = false) {
            self.name = name
            self.associatedTypes = associatedTypes
            self.indirect = indirect
        }

        public var textBody: some TextDocument {
            if indirect {
                "indirect".suffix(String.space)
            }
            "case "
            name
            ForEach(associatedTypes, separator: .commaSpace, content: { $0 }).parenthical(.round)
        }
    }
}
