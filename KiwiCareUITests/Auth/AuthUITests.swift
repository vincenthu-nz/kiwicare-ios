//
//  AuthUITests.swift
//  KiwiCareUITests
//

import XCTest

// MARK: - AuthUITests

/// UI tests for the login and registration flows.
/// These tests launch the real app and interact with it via the accessibility tree.
final class AuthUITests: XCTestCase {

    // MARK: - Properties

    private var app: XCUIApplication!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        // Pass a flag so the app can skip the Keychain token check and always show LoginView
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Login Screen

    func test_loginScreen_displaysExpectedElements() {
        XCTAssertTrue(app.staticTexts["KiwiCare"].exists)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }

    func test_loginScreen_signInButton_disabledByDefault() {
        // The button is enabled (no client-side disable before tap),
        // but tapping with empty fields should show a validation error
        let signInButton = app.buttons["Sign In"]
        signInButton.tap()

        XCTAssertTrue(app.alerts["Error"].exists)
    }

    func test_loginScreen_showsRegisterScreen_onSignUpTap() {
        app.buttons["Don't have an account? Sign Up"].tap()

        XCTAssertTrue(app.staticTexts["Create Account"].waitForExistence(timeout: 2))
    }

    // MARK: - Register Screen

    func test_registerScreen_displaysExpectedFields() {
        app.buttons["Don't have an account? Sign Up"].tap()

        XCTAssertTrue(app.textFields["Full Name"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.textFields["Phone (optional)"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        XCTAssertTrue(app.secureTextFields["Confirm Password"].exists)
    }

    func test_registerScreen_createAccountButton_disabledWhenFieldsEmpty() {
        app.buttons["Don't have an account? Sign Up"].tap()

        let createButton = app.buttons["Create Account"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2))
        XCTAssertFalse(createButton.isEnabled)
    }

    func test_registerScreen_passwordMismatch_showsInlineWarning() {
        app.buttons["Don't have an account? Sign Up"].tap()

        app.textFields["Full Name"].tap()
        app.textFields["Full Name"].typeText("Test User")

        app.textFields["Email"].tap()
        app.textFields["Email"].typeText("test@kiwicare.com")

        app.secureTextFields["Password"].tap()
        app.secureTextFields["Password"].typeText("password123")

        app.secureTextFields["Confirm Password"].tap()
        app.secureTextFields["Confirm Password"].typeText("differentpass")

        XCTAssertTrue(app.staticTexts["Passwords do not match."].exists)
    }
}
