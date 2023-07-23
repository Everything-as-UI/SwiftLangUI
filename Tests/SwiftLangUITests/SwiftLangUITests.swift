//
//  SwiftLangUITests.swift
//  
//
//  Created by Denis Koryttsev on 8.04.23.
//

import XCTest
import SwiftLangUI

final class SwiftLangUITests: XCTestCase {}

// MARK: - ProtocolDecl

extension SwiftLangUITests {
    func testProtocol() {
        let var1 = ProtocolDecl.Var(name: "dataSource", type: "[String]")
        let func1 = Function(name: "viewDidLoad")
        let protocolDecl = ProtocolDecl(name: "SomeModuleInput", vars: [var1], funcs: [func1])
        print("\(protocolDecl)")
    }

    func testProtocolImplementation() {
        let var1 = ProtocolDecl.Var(name: "dataSource", type: "[String]", mutable: false)
        let func1 = Function(name: "viewDidLoad", result: "Void")
        let protocolDecl = ProtocolDecl(name: "SomeModuleInput", vars: [var1], funcs: [func1])
        let defImpl = protocolDecl.implementation(inExtension: true, with: .context(""))
        print("\(defImpl)")
    }

    func testEnum() {
        let enumType = Enum(typeName: "Variants", inherits: ["String"], modifiers: [.public], cases: [
            Enum.Case(name: "variant1", associatedTypes: [ClosureDecl.Arg(label: nil, type: "String")]),
            Enum.Case(name: "variant2", indirect: true)
        ])
        print("\(enumType)")
    }

    func testObject() throws {
        let objectType = ObjectType.class(name: "SomeObject", modifiers: [.public, .final], properties: [
            Variable(name: "string", type: "String", mutable: true, body: .computed(Variable.ComputedBody(getter: "\"value\"")))
        ], functions: [
            .initializer() {
                "print(Self.self)"
            },
            FunctionV2(name: "doSomething") {}
        ])
        print("\(objectType)")
    }
}

// MARK: - DocumentUI

import DocumentUI

extension SwiftLangUITests {
    func testJSONGen() throws {
        let json = """
        {"x":"X","y":0,"z":true,"q":0.0,"n":null,"a":[0.0],"d":{"0":2}}
        """
        let jsonObj = try JSONSerialization.jsonObject(with: json.data(using: .utf8)!) as! NSDictionary
        func type(of value: Any) -> String? {
            switch value {
            case _ as String: return "String"
            case let nsValue as NSValue:
                switch Unicode.Scalar(UInt8(nsValue.objCType.pointee)) {
                case "c": return "Bool"
                case "q": return "Int"
                case "f", "d": return "Double"
                default: return nil
                }
            case let nsArray as NSArray: return "[\(type(of: nsArray.firstObject as AnyObject))]"
            case let nsDict as NSDictionary: return "[String: \(type(of: nsDict.first(where: { _ in true })?.value as AnyObject))]"
            case _ as NSNull: return "_?"
            default: return nil
            }
        }
        let template = Group {
            DeclWithBody(decl: TypeDecl(name: "Struct", modifiers: [.struct], inherits: ["Codable"])) {
                ForEach(jsonObj as! [String: Any], separator: "\n") { element in
                    let type = type(of: element.value)
                    VarDecl(name: element.key, type: type ?? "undefined", modifiers: [.let]).prefix(type == nil ? "// " : "")
                }
            }
        }
        print("\(template)")
    }
}

// MARK: - CoreUI

import CoreUI

extension String: Combinable {
    public func combined(with other: String) -> String {
        self + other
    }
}

struct JoinedStringKey: InheritableEnvironmentKey {
    static let defaultValue: String = ""
}
extension EnvironmentValues {
    var joinedString: String {
        set { self[JoinedStringKey.self] = newValue }
        get { self[JoinedStringKey.self] }
    }
}

struct SomeDoc: TextDocument {
    @Environment(\.joinedString) var joinedString

    var textBody: some TextDocument {
        joinedString
    }
}

extension SwiftLangUITests {
    func testInheritableEnvironmentKey() {
        let one = "one_"
        let two = "two"
        let doc = SomeDoc()
            .environment(\.joinedString, one)
            .environment(\.joinedString, two)
        let result = "\(doc)"
        print(result)
        XCTAssertEqual(result, one + two)
    }
}
