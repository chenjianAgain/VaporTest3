//
//  Language.swift
//  App
//
//  Created by Derek on 22/3/19.
//

import Foundation
import Vapor
import FluentMySQL

final class Language: Codable {
    var id: Int?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension Language: MySQLModel {}
extension Language: Migration {}
extension Language: Content {}
extension Language: Parameter {}

extension Language {
    var acronyms: Children<Language, Acronym> {
        return children(\.languageID)
    }
}

struct EnglishLanguage: Migration {
    typealias Database = MySQLDatabase
    
    static func prepare(on conn: MySQLConnection) -> Future<Void> {
        let englishLanguage = Language(name: "English")
        let chineseLanguage = Language(name: "中文")
        return map(to: Void.self, englishLanguage.save(on: conn), chineseLanguage.save(on: conn)) { _, _ in }
//        return language.save(on: conn).transform(to: ())
    }
    
    static func revert(on conn: MySQLConnection) -> Future<Void> {
        return .done(on: conn)
    }
}
