//
//  WebsiteController.swift
//  App
//
//  Created by Derek on 22/3/19.
//

import Foundation
import Vapor
import Authentication

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoute = router.grouped(User.authSessionsMiddleware())
        authSessionRoute.get(use: indexHandler)
        authSessionRoute.get("acronyms", Acronym.parameter, use: acronymHandler)
        authSessionRoute.get("login", use: loginHandler)
        authSessionRoute.post(LoginPostData.self, at: "login", use: loginPostHandler)
        authSessionRoute.post("logout", use: logoutHandler)
        
        let protectedRoute = authSessionRoute.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoute.get("acronyms", "create", use: createAcronymHandler)
        protectedRoute.post(AcronymCreateData.self, at: "acronyms", "create", use: createAcronymPostHandler)
        protectedRoute.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        protectedRoute.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        protectedRoute.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Acronym.query(on: req).all().flatMap(to: View.self) { acronyms in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let context = IndexContext(acronyms: acronyms, userLoggedIn: userLoggedIn)
            return try req.view().render("index", context)
        }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
            return acronym.language.get(on: req).flatMap(to: View.self) { language in
                let context = AcronymContext(title: acronym.name, acronym: acronym, language: language)
                return try req.view().render("acronym", context)
            }
        }
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> {
        let context = CreateAcronymContext(languages: Language.query(on: req).all())
        return try req.view().render("createAcronym", context)
    }
    
    func createAcronymPostHandler(_ req: Request, acronymData: AcronymCreateData) throws -> Future<Response> {
        let user = try req.requireAuthenticated(User.self)
        let acronym = try Acronym(name: acronymData.name, meaning: acronymData.meaning, languageID: acronymData.languageID, userID: user.requireID())
        return acronym.save(on: req).map(to: Response.self) { acronym in
            guard let id = acronym.id else {
                return req.redirect(to: "/")
            }
            return req.redirect(to: "/acronyms/\(id)")
        }
    }
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Acronym.self).flatMap(to: View.self) { acronym in
            let context = EditAcronymContext(acronym: acronym, languages: Language.query(on: req).all())
            return try req.view().render("createAcronym", context)
        }
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self).flatMap(to: Response.self) { acronym in
            let updatedAcronym = try req.content.syncDecode(AcronymCreateData.self)
            acronym.name = updatedAcronym.name
            acronym.meaning = updatedAcronym.meaning
            let user = try req.requireAuthenticated(User.self)
            acronym.userID = try user.requireID()
            
            return acronym.save(on: req).map(to: Response.self) { savedAcronym in
                guard let id = savedAcronym.id else {
                    return req.redirect(to: "/")
                }
                return req.redirect(to: "/acronyms/\(id)")
            }
        }
    }
    
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(Acronym.self).flatMap(to: Response.self) { acronym in
            return acronym.delete(on: req).transform(to: req.redirect(to: "/"))
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return try req.view().render("login", context)
    }
    
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        return User.authenticate(username: userData.username, password: userData.password, using: BCryptDigest(), on: req).map(to: Response.self) { user in
            guard let user = user else {
                return req.redirect(to: "/login?error")
            }
            try req.authenticateSession(user)
            return req.redirect(to: "/")
        }
    }
    
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        return req.redirect(to: "/")
    }
}

struct IndexContext: Encodable {
    let title = "Homepage"
    let acronyms: [Acronym]
    let userLoggedIn: Bool
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let language: Language
}

struct CreateAcronymContext: Encodable {
    let title = "Create An Acronym"
    let languages: Future<[Language]>
}

struct EditAcronymContext: Encodable {
    let title = "Edit Ascronym"
    let acronym: Acronym
    let languages: Future<[Language]>
    let editing = true
}

struct LoginContext: Encodable {
    let title = "Log In"
    let loginError: Bool
    
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
}

struct LoginPostData: Content {
    let username: String
    let password: String
}
