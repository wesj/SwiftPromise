//
//  SwiftPromiseTests.swift
//  SwiftPromiseTests
//
//  Created by Wes Johnston on 5/12/15.
//  Copyright (c) 2015 Wes Johnston. All rights reserved.
//

import UIKit
import SwiftPromise
import XCTest

class SwiftPromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testBasicResolution() {
        var p = Promise()
        p.then({ value in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")
            return value
        })
        p.resolve(1)

        p.then({ value -> AnyObject? in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")
            return value
        }, onRejected: { (err) -> AnyObject? in
            XCTFail("Should not catch anything")
            return err
        })
    }

    func testBasicRejection() {
        var p = Promise()
        var once = false
        p.catch({ err in
            XCTAssertFalse(once, "Rejected only called once")
            once = true
            XCTAssertEqual(err as! String, "Error", "Resolved with correct error")
            return err
        })
        p.reject("Error")

        p.then({ value in
            return value
        }, onRejected: { err in
            println("Got \(err)")
            XCTAssertEqual(err as! String, "Error", "Resolved with correct error")
            return err
        })
    }

    func testResolvedChaining() {
        var p = Promise()
        p.then({ value in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")
            return 2
        }).then({ value in
            XCTAssertEqual(value as! Int, 2, "Resolved with correct value")
            return value
        }).catch { (err) -> AnyObject? in
            XCTFail("Should not catch anything")
            return err
        }
        p.resolve(1)
    }

    func testChainingPromises() {
        var p = Promise()
        p.then({ value -> AnyObject? in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")
            let p2 = Promise()
            p2.resolve(2)
            return p2
        }).then({ value -> AnyObject? in
            XCTAssertEqual(value as! Int, 2, "Resolved with correct value")
            return value
        }).catch({ (err) -> AnyObject? in
            XCTFail("Should not catch anything")
            return err
        })
        // p.resolve(1)
    }

    func testRejectChaining() {
        var p = Promise()
        p.then({ value -> AnyObject? in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")
            p.reject("Error")
            return value
        }).then({ value -> AnyObject? in
            XCTFail("Should not resolve any further anything")
            return value
        }).catch { (err: AnyObject?) -> AnyObject? in
            XCTAssertEqual(err as! String, "Error", "Resolved with correct error")
            return err
        }
        p.resolve(1)
    }

    func testChainingPromises2() {
        var p = Promise()
        p.then({ value -> AnyObject? in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")

            let p2 = Promise()
            dispatch_after(1, dispatch_get_main_queue(), { _ in
                p2.resolve(2)
            })
            return p2
        }).then({ (value) -> AnyObject? in
            XCTAssertEqual(value as! Int, 2, "Resolved with correct value")
            return value
        }).catch { err in
            XCTFail("Should not hit this")
            return nil
        }
        p.resolve(1)
    }

    func testAllSinglePromise() {
        var p1 = 1

        Promise.all([p1]).then({ (values) -> AnyObject? in
            let ret = values as! [AnyObject?]
            XCTAssertEqual(ret[0] as! Int, 1, "values 0 has right first value")
            return nil
        }, onRejected: { (err) -> AnyObject? in
            XCTFail("Should not hit this")
            return nil
        })
    }

    func testAllResolved() {
        var p1 = Promise()
        var p2 = 2
        var p3 = Promise()

        Promise.all([p1, p2, p3]).then({ (values) -> AnyObject? in
            let ret = values as! NSArray
            XCTAssertEqual(ret[0] as! Int, 1, "values 0 has right first value")
            XCTAssertEqual(ret[1] as! Int, 2, "values 1 has right first value")
            XCTAssertEqual(ret[2] as! Int, 3, "values 2 has right first value")
            return nil
        }, onRejected: { (err) -> AnyObject? in
            XCTFail("Should not hit this")
            return nil
        })

        p1.resolve(1)
        p3.resolve(3)
    }

    func testAllReject() {
        var p1 = Promise()
        var p2 = Promise()

        Promise.all([p1, p2]).then({ (values) -> AnyObject? in
            XCTFail("Should not hit this")
            return nil
        }, onRejected: { (err) -> AnyObject? in
            XCTAssertEqual("Error", err as! String, "Promise rejected")
            return nil
        })

        p1.reject("Error")
        let expectation = expectationWithDescription("Resolved")
        dispatch_after(1, dispatch_get_main_queue()) { () -> Void in
            p2.resolve(2)
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAllRejectTwice() {
        var p1 = Promise()
        var p2 = Promise()

        Promise.all([p1, p2]).then({ (values) -> AnyObject? in
            XCTFail("Should not hit this")
            return nil
        }, onRejected: { (err) -> AnyObject? in
            XCTAssertEqual("Error", err as! String, "Promise rejected")
            return nil
        })

        p1.reject("Error")
        let expectation = expectationWithDescription("Resolved")
        dispatch_after(1, dispatch_get_main_queue()) { () -> Void in
            p2.reject("Second err")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testRace() {
        var p1 = Promise()
        var p2 = Promise()

        Promise.race([p1, p2]).then({ (value) -> AnyObject? in
            XCTAssertEqual(value as! Int, 2, "Resolved with correct value")
            return nil
        }, onRejected: { (err) -> AnyObject? in
            XCTFail("Should not hit this")
            return nil
        })

        p2.resolve(2)
        p1.resolve(1)
    }

    func testRaceReject() {
        var p1 = Promise()
        var p2 = Promise()

        Promise.race([p1, p2]).then({ (value) -> AnyObject? in
            XCTFail("Should not hit this")
            return nil
        }, onRejected: { (err) -> AnyObject? in
            XCTAssertEqual(err as! String, "Error", "Rejected with correct value")
            return nil
        })

        p2.reject("Error")
        p1.resolve(1)
    }

}
