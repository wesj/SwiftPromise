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

class YielderTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testBasicYielder() {
        let doAsync = Yielder({ yield -> Int? in
            for i in 0..<2 {
                yield(res: i)
            }
            return nil
        })

        XCTAssertEqual(doAsync()!, 0, "Initial call returns 0")
        XCTAssertEqual(doAsync()!, 1, "Second call returns 1")
        XCTAssertNil(doAsync(), "Done returns nil")
        XCTAssertEqual(doAsync()!, 0, "Repeat loop starts")
    }

    func testBoringYielder() {
        let doAsync = Yielder({ yield -> String? in
            return "Food"
        })

        XCTAssertEqual(doAsync()!, "Food", "Initial call returns Food")
        XCTAssertEqual(doAsync()!, "Food", "Second call returns Food")
    }

}
