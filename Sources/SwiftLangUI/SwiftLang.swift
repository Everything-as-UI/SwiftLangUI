//
//  SwiftLang.swift
//
//
//  Created by Denis Koryttsev on 4.02.23.
//

import CoreUI
import DocumentUI

public enum Keyword: String { // TODO: separate to different enums
    case `class`, `enum`, `protocol`, `struct`, `typealias`, `extension`, `func`, initWord = "init"
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
    public func withBody<Body: TextDocument>(@TextDocumentBuilder _ body: @escaping () -> Body) -> some TextDocument {
        DeclWithBody(decl: self, body: body)
    }
}
