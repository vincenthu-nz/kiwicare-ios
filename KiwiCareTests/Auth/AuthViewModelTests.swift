//
//  AuthViewModelTests.swift
//  KiwiCareTests
//

import XCTest
@testable import KiwiCare

// MARK: - AuthViewModelTests

/// Unit tests for `AuthViewModel`.
///
/// All tests use `MockAuthService` — no real network calls are made.
/// `@MainActor` is required because `AuthViewModel` publishes state on the main thread.
@MainActor
final class AuthViewModelTests: XCTestCase {

    // MARK: - Properties

    private var mockService: MockAuthService!
    private var sut: AuthViewModel!          // sut = System Under Test

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockService = MockAuthService()
        sut = AuthViewModel(authService: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    // MARK: - Login — Success

    func test_login_success_setsIsAuthenticated() async {
        await sut.login(email: "test@kiwicare.com", password: "password123")

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(mockService.loginCallCount, 1)
    }

    func test_login_success_setsCurrentUser() async {
        await sut.login(email: "test@kiwicare.com", password: "password123")

        XCTAssertEqual(sut.currentUser?.email, User.mock.email)
    }

    // MARK: - Login — Failure

    func test_login_networkFailure_setsErrorMessage() async {
        mockService.shouldFail = true

        await sut.login(email: "test@kiwicare.com", password: "password123")

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Login — Validation

    func test_login_emptyEmail_setsValidationError_andSkipsService() async {
        await sut.login(email: "", password: "password123")

        XCTAssertEqual(sut.errorMessage, "Email cannot be empty.")
        XCTAssertEqual(mockService.loginCallCount, 0)
    }

    func test_login_invalidEmail_setsValidationError_andSkipsService() async {
        await sut.login(email: "notanemail", password: "password123")

        XCTAssertEqual(sut.errorMessage, "Please enter a valid email address.")
        XCTAssertEqual(mockService.loginCallCount, 0)
    }

    func test_login_shortPassword_setsValidationError_andSkipsService() async {
        await sut.login(email: "test@kiwicare.com", password: "123")

        XCTAssertEqual(sut.errorMessage, "Password must be at least 8 characters.")
        XCTAssertEqual(mockService.loginCallCount, 0)
    }

    // MARK: - Register — Success

    func test_register_success_setsIsAuthenticated() async {
        await sut.register(
            name: "New User",
            email: "new@kiwicare.com",
            password: "password123",
            phone: nil
        )

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(mockService.registerCallCount, 1)
    }

    // MARK: - Register — Failure

    func test_register_networkFailure_setsErrorMessage() async {
        mockService.shouldFail = true

        await sut.register(
            name: "New User",
            email: "new@kiwicare.com",
            password: "password123",
            phone: nil
        )

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }

    // MARK: - Logout

    func test_logout_afterLogin_clearsAllState() async {
        await sut.login(email: "test@kiwicare.com", password: "password123")
        XCTAssertTrue(sut.isAuthenticated)

        sut.logout()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
    }

    // MARK: - Error Clearing

    func test_clearError_removesErrorMessage() async {
        mockService.shouldFail = true
        await sut.login(email: "test@kiwicare.com", password: "password123")
        XCTAssertNotNil(sut.errorMessage)

        sut.clearError()

        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Loading State

    func test_isLoading_isFalseAfterCompletion() async {
        await sut.login(email: "test@kiwicare.com", password: "password123")

        XCTAssertFalse(sut.isLoading)
    }
}
