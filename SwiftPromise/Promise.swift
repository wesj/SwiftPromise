//
//  Promise.swift
//  SwiftPromise
//
//  Created by Wes Johnston on 5/12/15.
//  Copyright (c) 2015 Wes Johnston. All rights reserved.
//

import Foundation

public class Promise<T> {
    public typealias Fulfilled = (value: T) -> T
    public typealias Rejected = (err: AnyObject?) -> T?
    typealias Responses = (Fulfilled?, Rejected?)
    private var rejected: AnyObject? = nil
    private var resolved: T? = nil

    var position: Int = 0
    var thens = [Responses]()

    public init() { }

    public func then(onFulfilled: Fulfilled, onRejected: Rejected? = nil) -> Promise {
        if let r = resolved {
            onFulfilled(value: r)
        } else if let r: AnyObject = rejected {
            onRejected?(err: r)
        } else {
            thens.append((onFulfilled, onRejected))
        }
        return self
    }

    public func catch(onRejected: Rejected) -> Promise {
        thens.append((nil, onRejected))
        return self
    }

    private class func resolveIfDone<T>(p: Promise<[T]>, iterables: [T], results: [T]) {
        if p.rejected != nil {
            return
        }

        if results.count == iterables.count {
            p.resolve(results)
        }
    }

    public class func all<T>(iterables: [T]) -> Promise<[T]> {
        let p = Promise<[T]>()

        var results = [T]()

        for (index, a) in enumerate(iterables) {
            if let pro = a as? Promise<T> {
                pro.then({ value in
                    println("All resolved \(value)")
                    if index < results.count {
                        results.insert(value, atIndex: index)
                    } else {
                        results.append(value)
                    }
                    Promise.resolveIfDone(p, iterables: iterables, results: results)
                    return value
                }, onRejected: { err in
                    println("All reject \(err)")
                    p.reject(err)
                    return nil
                })
            } else {
                println("All not a promise? \(a)")
                if index < results.count {
                    results.insert(a, atIndex: index)
                } else {
                    results.append(a)
                }
                Promise.resolveIfDone(p, iterables: iterables, results: results)
            }
        }

        return p
    }

    public class func race<T>(iterables: [T]) -> Promise<T> {
        let p = Promise<T>()

        for (index, a) in enumerate(iterables) {
            if let pro = a as? Promise<T> {
                pro.then({ value in
                    if p.resolved != nil && p.rejected != nil {
                        p.resolve(value)
                    }
                    return value
                }, onRejected: { err in
                    if p.resolved != nil && p.rejected != nil {
                        p.reject(err)
                    }
                    return nil
                })
            } else {
                if p.resolved != nil && p.rejected != nil {
                    p.resolve(a)
                }
            }
        }

        return p
    }

    public func reject(err: AnyObject?) {
        resolved = nil
        rejected = err
        if position >= thens.count {
            return
        }

        if let then = thens[position].1 {
            position++
            if let resolved = then(err: rejected) {
                if let p = resolved as? Promise<T> {
                    p.then({ value in
                        self.resolve(value)
                        return value
                    }, onRejected: { err in
                        self.reject(err!)
                        return nil
                    })
                } else {
                    resolve(resolved)
                }
            } else {
                reject(nil)
            }
        } else {
            position++
            reject(err)
        }
    }

    public func resolve(value: T) {
        resolved = value
        rejected = nil

        if position >= thens.count {
            return
        }

        if let then = thens[position].0 {
            position++
            resolved = then(value: value)

            if let p = resolved as? Promise {
                p.then({ value in
                    self.resolve(value)
                    return value
                }, onRejected: { err in
                    self.reject(err!)
                    return nil
                })
            } else {
                resolve(resolved!)
            }
        } else {
            position++
            resolve(value)
        }
    }
}

func foo() {
    var p = Promise<Int>()

    p.then({ value in
        return value
    }).catch({ err in
        return nil
    })
    p.resolve(1)
}


