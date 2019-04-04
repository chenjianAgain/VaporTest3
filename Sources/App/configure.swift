import FluentMySQL
import Vapor
import Leaf
import Authentication

// docker run --name mysql -e MYSQL_USER=derekcoder -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=acronym -p 3306:3306 -d mysql/mysql-server:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
// docker run --name mysql-test -e MYSQL_USER=derekcoder -e MYSQL_PASSWORD=password -e MYSQL_DATABASE=acronym-test -p 3307:3306 -d mysql/mysql-server:5.7 --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
// docker stop mysql
// docker rm mysql
// docker exec -it mysql mysql -u derekcoder -ppassword
// docker exec -it mysql-test mysql -u derekcoder -ppassword
// revert --all --yes

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first
    try services.register(FluentMySQLProvider())
    try services.register(LeafProvider())
    try services.register(AuthenticationProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    middlewares.use(SessionsMiddleware.self)
    services.register(middlewares)
    
    let hostname = Environment.get("DATABASE_HOSTNAME") ?? "35.238.101.198"
    let username = Environment.get("DATABASE_USER") ?? "derekcoder"
    let password = Environment.get("DATABASE_PASSWORD") ?? "password"
    let databaseName: String
    let databasePort: Int
    if env == .testing {
        databaseName = "acronym-test"
        if let testPort = Environment.get("DATABASE_PORT") {
            databasePort = Int(testPort) ?? 3307
        } else {
            databasePort = 3307
        }
    } else {
        databaseName = Environment.get("DATABASE_DB") ?? "acronym"
        databasePort = 3306
    }
    let databaseConfig = MySQLDatabaseConfig(hostname: hostname,
                                             port: databasePort,
                                             username: username,
                                             password: password,
                                             database: databaseName)

    // Configure a MySQL database
//    let databaseConfig = MySQLDatabaseConfig(hostname: "35.238.101.198", username: "derekcoder", password: "password", database: "acronym")
    let database = MySQLDatabase(config: databaseConfig)

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: database, as: .mysql)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .mysql)
    switch env {
    case .development, .testing:
        migrations.add(migration: AdminUser.self, database: .mysql)
    default: break
    }
    migrations.add(model: Language.self, database: .mysql)
    migrations.add(migration: EnglishLanguage.self, database: .mysql)
    migrations.add(model: Acronym.self, database: .mysql)
    migrations.add(model: Token.self, database: .mysql)
    
    services.register(migrations)
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
    var commandConfig = CommandConfig.default()
    commandConfig.useFluentCommands()
    services.register(commandConfig)
}
