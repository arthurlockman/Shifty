//
//  LogHelper.swift
//  Shifty
//
//  Bridges the logw() calls to apple/swift-log's Logging framework.
//

import Logging

private var logger = Logger(label: "io.natethompson.Shifty")

func logw(_ message: String, file: String = #file, function: String = #function, line: UInt = #line) {
    logger.warning("\(message)", file: file, function: function, line: line)
}
