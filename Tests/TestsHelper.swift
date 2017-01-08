//
// SwiftGenKit
// Copyright (c) 2017 Olivier Halligon
// MIT Licence
//

import Foundation
import XCTest
import PathKit

private let colorCode: (String) -> String = ProcessInfo().environment["XcodeColors"] == "YES" ? { "\u{001b}[\($0);" } : { _ in "" }
private let (msgColor, reset) = (colorCode("fg250,0,0"), colorCode(""))
private let okCode = (num: colorCode("fg127,127,127"), code: colorCode(""))
private let koCode = (num: colorCode("fg127,127,127") + colorCode("bg127,0,0"), code: colorCode("fg250,250,250") + colorCode("bg127,0,0"))

func diff(_ result: [String: Any], _ expected: [String: Any], path: String = "") -> String? {
  
  // check keys
  if Set(result.keys) != Set(expected.keys) {
    let lhs = result.keys.map{" - \($0): \(result[$0]!)"}.joined(separator: "\n")
    let rhs = expected.keys.map{" - \($0): \(result[$0]!)"}.joined(separator: "\n")
    let path = (path != "") ? " at '\(path)'" : ""
    return "\(msgColor)Keys do not match\(path):\(reset)\n>>>>>> result\n\(lhs)\n======\n\(rhs)\n<<<<<< expected"
  }
  
  // check values
  for (key, lhs) in result {
    guard let rhs = expected[key] else { continue }
    
    if let error = compare(lhs, rhs, key: key, path: path) {
      return error
    }
  }
  
  return nil
}

func compare(_ lhs: Any, _ rhs: Any, key: String, path: String) -> String? {
  let keyPath = (path == "") ? key : "\(path).\(key)"
  
  if let lhs = lhs as? Int, let rhs = rhs as? Int, lhs == rhs { return nil }
  else if let lhs = lhs as? Float, let rhs = rhs as? Float, lhs == rhs { return nil }
  else if let lhs = lhs as? String, let rhs = rhs as? String, lhs == rhs { return nil }
  else if let lhs = lhs as? [Any], let rhs = rhs as? [Any], lhs.count == rhs.count {
    for (lhs, rhs) in zip(lhs, rhs) {
      if let error = compare(lhs, rhs, key: key, path: path) {
        return error
      }
    }
  } else if let lhs = lhs as? [String: Any], let rhs = rhs as? [String: Any] {
    return diff(lhs, rhs, path: "\(keyPath)")
  } else {
    return "\(msgColor)Values do not match for '\(keyPath)':\(reset)\n>>>>>> result\n\(lhs)\n======\n\(rhs)\n<<<<<< expected"
  }
  
  return nil
}

func XCTDiffContexts(_ result: [String: Any], _ expected: [String: Any], file: StaticString = #file, line: UInt = #line) {
  guard let error = diff(result, expected) else { return }
  XCTFail(error, file: file, line: line)
}

class Fixtures {
  private static let testBundle = Bundle(for: Fixtures.self)
  private init() {}

  static func directory(subDirectory subDir: String? = nil) -> Path {
    guard let rsrcURL = testBundle.resourceURL else {
      fatalError("Unable to find resource directory URL")
    }
    let rsrc = Path(rsrcURL.path)

    guard let dir = subDir else { return rsrc }
    return rsrc + dir
  }

  static func path(for name: String, subDirectory: String = "fixtures") -> Path {
    guard let path = testBundle.path(forResource: name, ofType: "", inDirectory: subDirectory) else {
      fatalError("Unable to find fixture \"\(name)\"")
    }
    return Path(path)
  }

  static func string(for name: String, encoding: String.Encoding = .utf8) -> String {
    let subDir: String = name.hasSuffix(".stencil") ? "templates" : "fixtures"
    do {
      return try path(for: name, subDirectory: subDir).read(encoding)
    } catch let e {
      fatalError("Unable to load fixture content: \(e)")
    }
  }
  
  static func context(for name: String) -> [String: Any] {
    let path = self.path(for: name, subDirectory: "expected")
    
    guard let data = NSDictionary(contentsOfFile: path.description) as? [String: Any] else {
      fatalError("Unable to load fixture content")
    }
    
    return data
  }
}
