//
//  User.swift
//  App
//
//  Created by derekcoder on 22/3/19.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

final class User: Codable {
    var id: UUID?
    var username: String
    var name: String
    var password: String
    var email: String
    
    final class Public: Codable {
        var id: UUID?
        var username: String
        var name: String
        
        init(id: UUID?, username: String, name: String) {
            self.id = id
            self.username = username
            self.name = name
        }
    }
    
    init(username: String, name: String, password: String, email: String) {
        self.username = username
        self.name = name
        self.password = password
        self.email = email
    }
}

extension User: MySQLUUIDModel {}
extension User: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.unique(on: \.username)
            builder.unique(on: \.email)
        }
    }
}
extension User: Content {}
extension User: Parameter {}
extension User {
    var acronyms: Children<User, Acronym> {
        return children(\.userID)
    }
}

extension User.Public: Content {}

extension User {
    func convertToPublic() -> User.Public {
        let publicUser = User.Public(id: id, username: username, name: name)
        publicUser.id = self.id
        return publicUser
    }
}

extension Future where T: User {
    func convertToPublic() -> Future<User.Public> {
        return map(to: User.Public.self) { user in
            return user.convertToPublic()
        }
    }
}

extension User: BasicAuthenticatable {
    static let usernameKey: UsernameKey = \User.username
    static let passwordKey: PasswordKey = \User.password
}

extension User: TokenAuthenticatable {
    typealias TokenType = Token
}

extension User: PasswordAuthenticatable {}
extension User: SessionAuthenticatable {}

struct AdminUser: Migration {
    typealias Database = MySQLDatabase
    
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        let password = try? BCrypt.hash("password")
        guard let hashedPassword = password else {
            fatalError("Failed to create admin user")
        }
        
        let user = User(username: "admin", name: "Admin", password: hashedPassword, email: "admin@localhost.local")
        return user.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: MySQLConnection) -> Future<Void> {
        return .done(on: conn)
    }
}
