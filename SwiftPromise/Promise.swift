//
//  Promise.swift
//  SwiftPromise
//
//  Created by Wes Johnston on 5/12/15.
//  Copyright (c) 2015 Wes Johnston. All rights reserved.
//

import Foundation

public class Fulfilled<T> {
    let fun: (value: T) -> T
    init(fun: (value: T) -> T) {
        self.fun = fun
    }
}

public class Promise {
    public typealias Rejected = (err: Any?) -> Any?
    private var rejected: Any? = nil
    private var resolved: Any? = nil

    var position: Int = 0
    var thens = [(Fulfilled?, Rejected?)]()

    public init() { }

    public func then<T: Any>(onFulfilled: (value: T) -> T, onRejected: ((err: Any?) -> T?)? = nil) -> Promise {
        if let r = resolved as? T {
            onFulfilled(value: r)
        } else if let r: Any = rejected {
            onRejected?(err: r)
        } else {
            thens.append((onFulfilled as? Fulfilled, onRejected as? Rejected))
        }
        return self
    }

    public func catch<T: Any>(onRejected: (err: Any?) -> T?) -> Promise {
        thens.append((nil, onRejected as? Rejected))
        return self
    }

    private class func resolveIfDone<T>(p: Promise, iterables: [T], results: [T]) {
        if p.rejected != nil {
            return
        }

        if results.count == iterables.count {
            p.resolve(results)
        }
    }

    public class func all<T>(iterables: [T]) -> Promise {
        let p = Promise()

        var results = [T]()

        for (index, a) in enumerate(iterables) {
            if let pro = a as? Promise {
                pro.then({ (value: T) in
                    if index < results.count {
                        results.insert(value, atIndex: index)
                    } else {
                        results.append(value)
                    }
                    Promise.resolveIfDone(p, iterables: iterables, results: results)
                    return value
                }, onRejected: { err in
                    p.reject(err)
                    return nil
                })
            } else {
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

    public class func race<T>(iterables: [T]) -> Promise {
        let p = Promise()

        for (index, a) in enumerate(iterables) {
            if let pro = a as? Promise {
                pro.then({ (value: T) in
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

    public func reject(err: Any?) {
        resolved = nil
        rejected = err
        if position >= thens.count {
            return
        }

        if let then = thens[position].1 {
            position++
            if let resolved = then(err: rejected) {
                if let p = resolved as? Promise {
                    p.then({ (value: Any) in
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

    public func resolve<T>(value: T) {
        resolved = value
        rejected = nil

        if position >= thens.count {
            return
        }

        if let then = thens[position].0 {
            position++
            resolved = then(value: value)

            if let p = resolved as? Promise {
                p.then({ (value: T) in
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
    var p = Promise()

    p.then({ value in
        return value
    }).catch({ (err: Any?) -> Int? in
        return nil
    })
    p.resolve(1)
}


