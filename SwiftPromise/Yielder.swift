import UIKit
import Foundation

let logQueue = dispatch_queue_create("logger", DISPATCH_QUEUE_SERIAL)
public func log(msg: String) {
    dispatch_async(logQueue) {
        println(msg)
    }
}

private class Waiter {
    var waiting = false
    let condition = NSCondition()
    let name: String

    init(name: String) {
        self.name = name
    }

    func wait() {
        if waiting {
            return
        }
        // log("Wait \(name)")
        waiting = true
        condition.lock()
        while waiting {
            condition.wait()
        }
    }

    func resume() {
        if !waiting {
            return
        }
        // log("Resume \(name)")
        waiting = false
        condition.signal()
        condition.unlock()
    }
}

public func Yielder<T>(fun: (yield: (res: T) -> Void) -> T?) -> (() -> T?) {
    let queue = dispatch_queue_create("YielderQueue", DISPATCH_QUEUE_CONCURRENT)
    var waiter: Waiter? = nil
    let waiting2 = Waiter(name: "MainThread")
    var result: T? = nil

    return { _ in
        if waiter?.waiting ?? false {
            dispatch_async(queue) {
                waiter?.resume()
            }
            waiting2.wait()
        } else {
            waiter = Waiter(name: "BackgroundThread")
            dispatch_async(queue) {
                result = fun(yield: { res in
                    log("result \(res)")
                    result = res
                    // We want to resume the main thread after this one is done.
                    // That's hard to do it turns out. This is kinda a hack...
                    dispatch_async(queue) {
                        waiting2.resume()
                    }
                    waiter?.wait()
                })
                waiting2.resume()
                waiter = nil
            }
            waiting2.wait()
        }

        return result
    }
}
