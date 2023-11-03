//
//  Extensions.swift
//  
//
//  Created by Denis Koryttsev on 11.03.23.
//

import DocumentUI

public extension String {
    static let space = " "
    static let newline = "\n"
    static let comma = ","
    static var commaSpace: Self { comma + space }
    static let arrow = "->"
    static let dot = "."

    func repeating(_ count: Int) -> Self {
        Self(repeating: self, count: count)
    }
}

public extension String {
    func startsLowercased() -> String {
        prefix(1).lowercased() + dropFirst()
    }
    func startsUppercased() -> String {
        prefix(1).uppercased() + dropFirst()
    }
}

public extension TextDocument {
    func starting(with repeatingString: String, count: Int = 1) -> _ModifiedDocument<Self, Prefix<String>> {
        prefix(String(repeating: repeatingString, count: count))
    }
    func ending(with repeatingString: String, count: Int = 1) -> _ModifiedDocument<Self, Suffix<String>> {
        suffix(String(repeating: repeatingString, count: count))
    }

    func startingWithNewline(_ count: Int = 1) -> _ModifiedDocument<Self, Prefix<String>> {
        starting(with: .newline, count: count)
    }
    func endingWithNewline(_ count: Int = 1) -> _ModifiedDocument<Self, Suffix<String>> {
        ending(with: .newline, count: count)
    }
}
