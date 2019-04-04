//
//  Acronym.swift
//  AcronymAppPackageDescription
//
//  Created by Derek on 22/3/19.
//

import Foundation
import Vapor
import FluentMySQL

final class Acronym: Codable {
    var id: Int?
    var name: String
    var meaning: String
    var languageID: Language.ID
    var userID: User.ID
    
    init(name: String, meaning: String, languageID: Language.ID, userID: User.ID) {
        self.name = name
        self.meaning = meaning
        self.languageID = languageID
        self.userID = userID
    }
}

extension Acronym: MySQLModel {}
extension Acronym: Content {}
extension Acronym: Migration {
    static func prepare(on connection: MySQLConnection) -> Future<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.userID, to: \User.id)
            builder.reference(from: \.languageID, to: \Language.id)
        }
    }
}
extension Acronym: Parameter {}

extension Acronym {
    var language: Parent<Acronym, Language> {
        return parent(\.languageID)
    }
    
    var user: Parent<Acronym, User> {
        return parent(\.userID)
    }
}
