//
//  UsersController.swift
//  App
//
//  Created by derekcoder on 22/3/19.
//

import Foundation
import Vapor
import Fluent
import Crypto

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoute = router.grouped("api", "users")
        usersRoute.get(use: getAllHandler)
        usersRoute.get(User.parameter, use: getHandler)
        usersRoute.get(User.parameter, "acronyms", use: getAcronymsHandler)
        usersRoute.post(UserCreateData.self, use: createHandler)
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let basicAuthGroup = usersRoute.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)

        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let guardAuthMiddleware = User.guardAuthMiddleware()
        let tokenAuthGroup = usersRoute.grouped(tokenAuthMiddleware, guardAuthMiddleware)
        tokenAuthGroup.get("me", use: getMeHandler)
        tokenAuthGroup.post(User.parameter, "upgrade", use: upgradeHandler)
    }
    
    func createHandler(_ req: Request, userData: UserCreateData) throws -> Future<User.Public> {
        let user = try User(username: userData.username,
                            name: userData.name,
                            password: BCrypt.hash(userData.password),
                            email: userData.email,
                            role: User.Role.normal.rawValue)
        return user.save(on: req).convertToPublic()
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).convertToPublic()
    }
    
    func getMeHandler(_ req: Request) throws -> Future<User.Public> {
        let user = try req.requireAuthenticated(User.self)
        return req.future(user.convertToPublic())
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(User.self).flatMap(to: [Acronym].self) { user in
            return try user.acronyms.query(on: req).filter(\.state == Acronym.State.approved.rawValue).all()
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
    
    func upgradeHandler(_ req: Request) throws -> Future<HTTPStatus> {
        let user = try req.requireAuthenticated(User.self)
        guard user.role == User.Role.admin.rawValue else {
            return req.future(.forbidden)
        }
        return try req.parameters.next(User.self).flatMap(to: HTTPStatus.self) { needUpgradeUser in
            guard needUpgradeUser.role != User.Role.admin.rawValue else {
                return req.future(.ok)
            }
            needUpgradeUser.role = User.Role.admin.rawValue
            return needUpgradeUser.save(on: req).transform(to: .ok)
        }
    }    
}

struct UserCreateData: Content {
    let username: String
    let name: String
    let password: String
    let email: String
}
