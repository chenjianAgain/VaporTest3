import Vapor

public func routes(_ router: Router) throws {
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
    
    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
    
    let languagesController = LanguagesController()
    try router.register(collection: languagesController)
    
    let usersController = UsersController()
    try router.register(collection: usersController)
}
