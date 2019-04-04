@testable import App
import FluentMySQL
import Crypto

extension User {
    static func create(username: String? = nil, name: String = "Luke", on conn: MySQLConnection) throws -> User {
        let createUsername: String
        if let suppliedUsername = username {
            createUsername = suppliedUsername
        } else {
            createUsername = UUID().uuidString
        }
        
        let password = try BCrypt.hash("password")
        let user = User(username: createUsername, name: name, password: password, email: "\(createUsername)@test.com")
        return try user.save(on: conn).wait()
    }
}

extension Language {
    static func create(name: String = "English", on conn: MySQLConnection) throws -> Language {
        let language = Language(name: name)
        return try language.save(on: conn).wait()
    }
}

extension Acronym {
    static func create(name: String = "TIL",
                       meaning: String = "Today I Learned",
                       user: User? = nil,
                       language: Language? = nil,
                       on conn: MySQLConnection) throws -> Acronym {
        
        var acronymsUser = user
        if acronymsUser == nil {
            acronymsUser = try User.create(on: conn)
        }
        
        var acronymsLanguage = language
        if acronymsLanguage == nil {
            acronymsLanguage = try Language.create(on: conn)
        }
        
        let acronym = Acronym(name: name, meaning: meaning, languageID: acronymsLanguage!.id!, userID: acronymsUser!.id!)
        return try acronym.save(on: conn).wait()
    }
}
