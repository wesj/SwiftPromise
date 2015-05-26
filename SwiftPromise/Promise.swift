//
//  Promise.swift
//  SwiftPromise
//
//  Created by Wes Johnston on 5/12/15.
//  Copyright (c) 2015 Wes Johnston. All rights reserved.
//

import Foundation

public class Promise {
    public typealias Fulfilled = (value: AnyObject?) -> AnyObject?
    public typealias Rejected = (err: AnyObject?) -> AnyObject?
    typealias Responses = (Fulfilled?, Rejected?)
    private var rejected: AnyObject? = nil
    private var resolved: AnyObject? = nil

    var position: Int = 0
    var thens = [Responses]()
    public enum PromiseStatus {
        case Unresolved, Resolved, Rejected
    }
    public var status: PromiseStatus = .Unresolved

    public init() { }

    public func then(onFulfilled: Fulfilled, onRejected: Rejected? = nil) -> Promise {
        if let r: AnyObject = resolved {
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

    private class func resolveIfDone(p: Promise, iterables: [AnyObject], results: NSArray) {
        if p.rejected != nil {
            return
        }

        if results.count == iterables.count {
            p.resolve(results)
        }
    }

    public class func all(iterables: [AnyObject]) -> Promise {
        let p = Promise()

        var results = NSMutableArray() // [AnyObject?]()

        for (index, a) in enumerate(iterables) {
            if let pro = a as? Promise {
                pro.then({ (value) -> AnyObject? in
                    if index < results.count {
                        results.insertObject(value!, atIndex: index)
                    } else {
                        results.addObject(value!)
                    }
                    Promise.resolveIfDone(p, iterables: iterables, results: results)
                    return nil
                }, onRejected: { (err) -> AnyObject? in
                    p.reject(err)
                    return nil
                })
            } else {
                if index < results.count {
                    results.insertObject(a, atIndex: index)
                } else {
                    results.addObject(a)
                }
                Promise.resolveIfDone(p, iterables: iterables, results: results)
            }
        }

        return p
    }

    public class func race(iterables: [AnyObject]) -> Promise {
        let p = Promise()

        for (index, a) in enumerate(iterables) {
            if let pro = a as? Promise {
                pro.then({ (value) -> AnyObject? in
                    if p.resolved != nil && p.rejected != nil {
                        p.resolve(value!)
                    }
                    return nil
                }, onRejected: { (err) -> AnyObject? in
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
        rejected = err
        if position >= thens.count {
            return
        }

        if let then = thens[position].1 {
            position++
            let res: AnyObject? = then(err: rejected)

            if let p = res as? Promise {
                p.then({ (value) -> AnyObject? in
                    self.resolve(value!)
                    return nil
                }, onRejected: { (err) -> AnyObject? in
                    self.reject(err!)
                    return nil
                })
                return
            } else {
                reject(res ?? rejected!)
            }
        }
    }

    public func resolve(value: AnyObject) {
        if let r: AnyObject = rejected {
            println("This promise is already rejected. Rejecting again?")
            reject(r)
            return
        }

        if position >= thens.count {
            return
        }

        resolved = value
        if let then = thens[position].0 {
            position++
            let res: AnyObject? = then(value: resolved)

            if let p = res as? Promise {
                p.then({ value in
                    self.resolve(value!)
                    return nil
                }, onRejected: { err in
                    self.reject(err!)
                    return nil
                })
                return
            } else {
                resolve(res ?? resolved!)
            }
        }
    }
}

func foo() {
    var p = Promise()

    p.then({ value in
        return nil
    }).catch { (err) -> AnyObject? in
        return nil
    }
    p.resolve(1)
}


