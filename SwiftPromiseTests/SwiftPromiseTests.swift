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
        var p = Promise<Int>()
        p.then({ value in
            XCTAssertEqual(value, 1, "Resolved with correct value")
            return value
        })
        p.resolve(1)

        p.then({ value in
            XCTAssertEqual(value, 1, "Resolved with correct value")
            return value
        }, onRejected: { err in
            XCTFail("Should not catch anything")
            return nil
        })
    }

    func testBasicRejection() {
        var p = Promise<Int>()
        var once = false
        p.catch({ err in
            XCTAssertFalse(once, "Rejected only called once")
            once = true
            XCTAssertEqual(err as! String, "Error", "Resolved with correct error")
            return nil
        })
        p.reject("Error")

        p.then({ value in
            return value
        }, onRejected: { err in
            XCTAssertEqual(err as! String, "Error", "Resolved with correct error")
            return nil
        })
    }

    func testResolvedChaining() {
        var p = Promise<Int>()
        p.then({ value in
            XCTAssertEqual(value, 1, "Resolved with correct value")
            return 2
        }).then({ value in
            XCTAssertEqual(value, 2, "Resolved with correct value")
            return value
        }).catch { err in
            XCTFail("Should not catch anything")
            return nil
        }
        p.resolve(1)
    }

    func testChainingPromises() {
        var p = Promise<Any>()
        p.then({ value in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")
            let p2 = Promise<Any>()
            p2.resolve(2)
            return p2
        }).then({ value in
            XCTAssertEqual(value as! Int, 2, "Resolved with correct value")
            return value
        }).catch({ err in
            XCTFail("Should not catch anything")
            return nil
        })
        p.resolve(1)
    }

    func testRejectChaining() {
        var p = Promise<Any>()
        p.then({ value in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")
            var p2 = Promise<Any>()
            p2.reject("Error")
            return p2
        }).then({ value in
            XCTFail("Should not resolve any further anything")
            return value
        }).catch({ err in
            XCTAssertEqual(err as! String, "Error", "Resolved with correct error")
            return true
        }).then({ value in
            XCTAssertTrue(true, "True")
            return 3
        }).catch({ err in
            XCTFail("Fail")
            return nil
        })

        p.resolve(1)
    }

    func testMidpointRejecting() {
        var p = Promise<Int>()
        p.then({ value in
            XCTAssertEqual(value, 1, "Resolved with correct value")
            p.reject("Error")
            return value
        }).then({ value in
            XCTFail("Should not resolve any further anything")
            return value
        }).catch({ err in
            XCTAssertEqual(err as! String, "Error", "Resolved with correct error")
            return 2
        }).then({ value in
            XCTAssertEqual(value, 2, "True")
            return 2
        }).catch({ err in
            XCTFail("Fail")
            return nil
        })

        p.resolve(1)
    }


    func testChainingPromises2() {
        var p = Promise<Any>()
        p.then({ value in
            XCTAssertEqual(value as! Int, 1, "Resolved with correct value")

            let p2 = Promise<Any>()
            dispatch_after(1, dispatch_get_main_queue(), { _ in
                p2.resolve(2)
            })
            return p2
        }).then({ value in
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

        Promise<[Int]>.all([p1]).then({ values in
            XCTAssertEqual(values[0], 1, "values 0 has right first value")
            return values
        }, onRejected: { err in
            XCTFail("Should not hit this")
            return nil
        })
    }

    func testAllResolved() {
        var p1 = Promise<Any>()
        var p2 = 2
        var p3 = Promise<Any>()

        Promise<[Any]>.all([p1, p2, p3] as [Any]).then({ values in
            XCTAssertEqual(values[0] as! Int, 1, "values 0 has right first value")
            XCTAssertEqual(values[1] as! Int, 2, "values 1 has right first value")
            XCTAssertEqual(values[2] as! Int, 3, "values 2 has right first value")
            return values
        }, onRejected: { err in
            XCTFail("Should not hit this")
            return nil
        })

        p1.resolve(1)
        p3.resolve(3)
    }

    func testAllReject() {
        var p1 = Promise<Any>()
        var p2 = Promise<Any>()

        Promise<[Any]>.all([p1, p2] as [Any]).then({ values in
            XCTFail("Should not hit this")
            return values
        }, onRejected: { err in
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
        var p1 = Promise<Any>()
        var p2 = Promise<Any>()

        Promise<[Any]>.all([p1, p2] as [Any]).then({ values in
            XCTFail("Should not hit this")
            return values
        }, onRejected: { err in
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
        var p1 = Promise<Int>()
        var p2 = Promise<Int>()

        Promise<Any>.race([p1, p2] as [Any]).then({ value in
            XCTAssertEqual(value as! Int, 2, "Resolved with correct value")
            return value
        }, onRejected: { err in
            XCTFail("Should not hit this")
            return nil
        })

        p2.resolve(2)
        p1.resolve(1)
    }

    func testRaceReject() {
        var p1 = Promise<Int>()
        var p2 = Promise<Int>()

        Promise<Any>.race([p1, p2]).then({ value in
            XCTFail("Should not hit this")
            return value
        }, onRejected: { err in
            XCTAssertEqual(err as! String, "Error", "Rejected with correct value")
            return nil
        })

        p2.reject("Error")
        p1.resolve(1)
    }

}
