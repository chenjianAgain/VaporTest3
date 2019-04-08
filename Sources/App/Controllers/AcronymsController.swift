//
//  AcronymsController.swift
//  App
//
//  Created by Derek on 22/3/19.
//

import Foundation
import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoute = router.grouped("api", "acronyms")
        acronymsRoute.get(use: getAllHandler)
        acronymsRoute.get(Acronym.parameter, use: getHandler)
        acronymsRoute.get(Acronym.parameter, "user", use: getUserHandler)
        acronymsRoute.get("search", use: searchHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = acronymsRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.post(AcronymCreateData.self, use: createHandler)
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.post(Acronym.parameter, "approve", use: approveHandler)
        tokenAuthGroup.post(Acronym.parameter, "reject", use: rejectHandler)
        tokenAuthGroup.get("current", use: getCurrentUserAcronyms)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        if let state = req.query[String.self, at: "state"] {
            return Acronym.query(on: req).filter(\.state == state).all()
        } else {
            return Acronym.query(on: req).all()
        }
    }
    
    func getCurrentUserAcronyms(_ req: Request) throws -> Future<[Acronym]> {
        let user = try req.requireAuthenticated(User.self)
        return try user.acronyms.query(on: req).all()
    }
    
    func createHandler(_ req: Request, acronymData: AcronymCreateData) throws -> Future<Acronym> {
        let user = try req.requireAuthenticated(User.self)
        let state = user.isAdmin ? Acronym.State.approved.rawValue : Acronym.State.pending.rawValue
        let acronym = try Acronym(name: acronymData.name,
                                  meaning: acronymData.meaning,
                                  state: state,
                                  languageID: acronymData.languageID,
                                  userID: user.requireID())
        return acronym.save(on: req)
    }
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameters.next(Acronym.self)
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameters.next(Acronym.self).flatMap(to: HTTPStatus.self) { acronym in
            return acronym.delete(on: req).transform(to: .noContent)
        }
    }
    
    func updateHandler(_ req: Request) throws -> Future<Acronym> {
        return try flatMap(to: Acronym.self, req.parameters.next(Acronym.self), req.content.decode(AcronymCreateData.self)) { acronym, updatedAcronym in
            acronym.name = updatedAcronym.name
            acronym.meaning = updatedAcronym.meaning
            let user = try req.requireAuthenticated(User.self)
            acronym.userID = try user.requireID()
            return acronym.save(on: req)
        }
    }
    
    func getUserHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(Acronym.self).flatMap(to: User.Public.self) { acronym in
            return acronym.user.get(on: req).convertToPublic()
        }
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchQuery = req.query[String.self, at: "query"] else {
            throw Abort(.badRequest)
        }
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.name == searchQuery)
            or.filter(\.meaning == searchQuery)
        }.all()
    }
    
    func approveHandler(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        guard user.role == User.Role.admin.rawValue else {
            return req.future(HTTPStatus.forbidden)
        }
        
        return try req.parameters.next(Acronym.self).flatMap(to: HTTPStatus.self) { acronym in
            guard acronym.state != Acronym.State.approved.rawValue else {
                return req.future(.ok)
            }
            acronym.state = Acronym.State.approved.rawValue
            return acronym.save(on: req).transform(to: .ok)
        }
    }
    
    func rejectHandler(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        guard user.role == User.Role.admin.rawValue else {
            return req.future(HTTPStatus.forbidden)
        }

        return try req.parameters.next(Acronym.self).flatMap(to: HTTPStatus.self) { acronym in
            guard acronym.state != Acronym.State.rejected.rawValue else {
                return req.future(.ok)
            }
            acronym.state = Acronym.State.rejected.rawValue
            return acronym.save(on: req).transform(to: .ok)
        }
    }
}

struct AcronymCreateData: Content {
    let name: String
    let meaning: String
    let languageID: Language.ID
}
