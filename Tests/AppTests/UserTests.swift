@testable import App
import Vapor
import XCTest
import FluentMySQL

final class UserTests: XCTestCase {
    let usersUsername = "alicea"
    let usersName = "Alice"
    let usersURI = "/api/users/"
    var app: Application!
    var conn: MySQLConnection!
    
    
    override func setUp() {
        try! Application.reset()
        app = try! Application.testable()
        conn = try! app.newConnection(to: .mysql).wait()
    }
    
    override func tearDown() {
        conn.close()
        try? app.syncShutdownGracefully()
    }
    
    func testUsersCanBeRetrievedFromAPI() throws {
        let users = try app.getResponse(to: usersURI, decodeTo: [User.Public].self)
        
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users[0].name, "Admin")
        XCTAssertEqual(users[0].username, "admin")
    }
    
    
    func testUserCanBeSavedWithAPI() throws {
        let user = User(username: usersUsername, name: usersName, password: "password", email: "\(usersUsername)@test.com")
        
        let receivedUser = try app.getResponse(to: usersURI,
                                               method: .POST,
                                               headers: ["Content-Type": "application/json"],
                                               data: user,
                                               decodeTo: User.Public.self,
                                               loggedInRequest: true)
        
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertNotNil(receivedUser.id)
        
        let users = try app.getResponse(to: usersURI, decodeTo: [User.Public].self)

        XCTAssertEqual(users.count, 2)
    }
    
    func testGettingASingleUserFromAPI() throws {
        let user = try User.create(username: usersUsername, name: usersName, on: conn)
        let receivedUser = try app.getResponse(to: "\(usersURI)\(user.id!)", decodeTo: User.Public.self)
        
        XCTAssertEqual(receivedUser.username, usersUsername)
        XCTAssertEqual(receivedUser.name, usersName)
        XCTAssertEqual(receivedUser.id, user.id)
    }
    
    func testGettingAUsersAcronymsFromAPI() throws {
        let user = try User.create(on: conn)
        let language = try Language.create(on: conn)
        
        let acronymName = "OMG"
        let acronymMeaning = "Oh My God"
        
        let acronym = try Acronym.create(name: acronymName, meaning: acronymMeaning, user: user, language: language, on: conn)
        let acronyms = try app.getResponse(to: "\(usersURI)\(user.id!)/acronyms", decodeTo: [Acronym].self)
        
        XCTAssertEqual(acronyms.count, 1)
        XCTAssertEqual(acronyms[0].id, acronym.id)
        XCTAssertEqual(acronyms[0].name, acronymName)
        XCTAssertEqual(acronyms[0].meaning, acronymMeaning)
    }
    
    static let allTests = [
        ("testUsersCanBeRetrievedFromAPI", testUsersCanBeRetrievedFromAPI),
        ("testUserCanBeSavedWithAPI", testUserCanBeSavedWithAPI),
        ("testGettingASingleUserFromAPI", testGettingASingleUserFromAPI),
        ("testGettingAUsersAcronymsFromAPI", testGettingAUsersAcronymsFromAPI)
    ]
}
