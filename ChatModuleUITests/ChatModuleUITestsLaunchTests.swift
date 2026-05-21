//
//  ChatModuleUITestsLaunchTests.swift
//  ChatModuleUITests
//
//  Created by Casssiano Leão on 15/05/26.
//

import XCTest

final class ChatModuleUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Capture a screenshot of the initial chat surface for visual regression review.
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(iOS 16.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
