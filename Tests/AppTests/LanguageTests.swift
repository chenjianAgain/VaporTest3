@testable import App
import Vapor
import XCTest
import FluentMySQL

final class LanguageTests: XCTestCase {
    let languagesName = "Chinese"
    let languagesURI = "/api/languages/"
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
    
    func testLanguagesCanBeRetrievedFromAPI() throws {
        let languages = try app.getResponse(to: languagesURI, decodeTo: [Language].self)

        XCTAssertEqual(languages.count, 2)
    }
    
    func testGettingASingleLanguageFromAPI() throws {
        let language = try Language.create(name: languagesName, on: conn)
        
        let receivedLanguage =
            try app.getResponse(to: "\(languagesURI)\(language.id!)",
                                decodeTo: Language.self)
        
        XCTAssertEqual(receivedLanguage.name, languagesName)
        XCTAssertEqual(receivedLanguage.id, language.id)
    }
    
    static let allTests = [
        ("testLanguagesCanBeRetrievedFromAPI", testLanguagesCanBeRetrievedFromAPI),
        ("testGettingASingleLanguageFromAPI", testGettingASingleLanguageFromAPI)
    ]
}
