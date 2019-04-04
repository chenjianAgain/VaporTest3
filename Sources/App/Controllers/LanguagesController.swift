//
//  LanguagesController.swift
//  App
//
//  Created by Derek on 22/3/19.
//

import Foundation
import Vapor
import Fluent

struct LanguagesController: RouteCollection {
    func boot(router: Router) throws {
        let languagesRoute = router.grouped("api", "languages")
        languagesRoute.get(use: getAllHandler)
        languagesRoute.get(Language.parameter, use: getHandler)
        
        /*
         * Currently no need: create, update and delete for language
         * Disable first
         *
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = languagesRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.delete(Language.parameter, use: deleteHandler)
        tokenAuthGroup.put(Language.parameter, use: updateHandler)
        */
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Language]> {
        return Language.query(on: req).all()
    }
    
    func createHandler(_ req: Request) throws -> Future<Language> {
        return try req.content.decode(Language.self).flatMap(to: Language.self) { language in
            return language.save(on: req)
        }
    }
    
    func getHandler(_ req: Request) throws -> Future<Language> {
        return try req.parameters.next(Language.self)
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Language.self).flatMap(to: HTTPStatus.self) { language in
            return language.delete(on: req).transform(to: .noContent)
        }
    }
    
    func updateHandler(_ req: Request) throws -> Future<Language> {
        return try flatMap(to: Language.self, req.parameters.next(Language.self), req.content.decode(Language.self)) { language, updatedLanguage in
            language.name = updatedLanguage.name
            return language.save(on: req)
        }
    }
}
