//
//  PublicSuffix.swift
//  PublicSuffix
//
//  Created by Enrico Ghirardi on 28/11/2017.
//  Copyright © 2017 Enrico Ghirardi. All rights reserved.
//

import Foundation

private let PSL_RULES_NAME  = "etld"
private let PSL_RULES_FORMAT = "plist"
private var _ruleTree: [String: Any] = [:]

private class PublicSuffix {
    public static var ownBundle: Bundle {
        return Bundle(for: PublicSuffix.self)
    }
}

extension URL {
    private func loadRuleTree(url: URL) -> [String: Any] {
        do {
            let data = try Data(contentsOf: url)
            return try PropertyListSerialization.propertyList(from: data,
                                                             options: [],
                                                             format: nil)
                as! [String: Any]
        } catch {
            NSLog("PSL: Couldn't load rule tree")
            return [:]
        }
    }

    private var PSLruleTree: [String: Any] {
        if !_ruleTree.isEmpty {
            return _ruleTree
        }
        if let ruleTreeURL = PublicSuffix.ownBundle.url(forResource: PSL_RULES_NAME,
                                                        withExtension: PSL_RULES_FORMAT) {
            _ruleTree = loadRuleTree(url: ruleTreeURL)
        }
        return _ruleTree
    }
    
    private func processRegisteredDomain(components: inout [String], ruleTree: [String: Any]) -> String? {
        if components.count == 0 {
            return nil
        }
        guard let lastComponent = components.last?.lowercased() else { return nil }
        components.removeLast()
        
        var result: String?
        if ruleTree[lastComponent] != nil {
            let subTree = ruleTree[lastComponent] as! [String: Any]
            if subTree["!"] != nil {
                return lastComponent
            } else {
                result = processRegisteredDomain(components: &components, ruleTree: subTree)
            }
        } else if ruleTree["*"] != nil {
            let subTree = ruleTree["*"] as! [String: Any]
            result = processRegisteredDomain(components: &components, ruleTree: subTree)
        } else {
            return lastComponent
        }
        
        guard let end_result = result else { return nil }
        if end_result.isEmpty {
            return nil
        } else {
            return "\(end_result).\(lastComponent)"
        }
    }
    
    public var registeredDomain: String? {
        get {
            if let self_host = self.host {
                if self_host.hasPrefix(".") || self_host.hasSuffix(".") {
                    return nil
                }
                var hostComponents: [String] = self_host.components(separatedBy: ".")
                if hostComponents.count < 2 {
                    return nil
                }
                return processRegisteredDomain(components: &hostComponents, ruleTree: PSLruleTree)
            }
            return nil
        }
    }
}
