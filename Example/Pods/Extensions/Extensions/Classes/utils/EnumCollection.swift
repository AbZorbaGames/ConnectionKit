//
//  EnumCollection.swift
//  Extensions
//
//  Created by Georges Boumis on 16/01/2017.
//  Copyright © 2016-2017 Georges Boumis.
//  Licensed under MIT (https://github.com/averello/Extensions/blob/master/LICENSE)
//
// source: https://theswiftdev.com/2017/01/05/18-swift-gist-generic-allvalues-for-enums/?utm_campaign=iOS%2BDev%2BWeekly&utm_medium=email&utm_source=iOS_Dev_Weekly_Issue_283
//

import Foundation


/// works only for contiguous enumerations starting from 0 
public protocol EnumCollection: RawRepresentable, Hashable {
    static var allValues: [Self] { get }
}

public extension EnumCollection where RawValue: Integer {
    
    static var allValues: [Self] {
        var index: Self.RawValue = 0
        let increment: Self.RawValue = 1

        return Array(AnyIterator {
            let id: Self.RawValue = index
            index += increment
            return Self(rawValue: id)
        })
    }
}

public extension EnumCollection {
    static func cases() -> AnySequence<Self> {
        typealias S = Self
        return AnySequence { () -> AnyIterator<S> in
            var raw = 0
            return AnyIterator {
                let current: Self = withUnsafePointer(to: &raw) { $0.withMemoryRebound(to: S.self, capacity: 1) { $0.pointee } }
                guard current.hashValue == raw else { return nil }
//                guard current.rawValue.hashValue == raw else { return nil }
                raw += 1
                return current
            }
        }
    }

    static var allValues: [Self] {
        return Array(self.cases())
    }
}

