import Foundation

// MARK: - DIContainerProtocol
/// Protocol for dependency injection container
/// Allows for easy testing by swapping implementations
protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - DIContainer
/// Dependency Injection Container - manages all app dependencies
/// Singleton pattern ensures single source of truth for dependencies
class DIContainer: DIContainerProtocol {
    static let shared = DIContainer()
    
    private var factories: [String: () -> Any] = [:]
    
    private init() {}
    
    /// Register a factory for creating instances of a type
    /// - Parameters:
    ///   - type: The type to register
    ///   - factory: Closure that creates the instance
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
        print("📦 Registered dependency: \(key)")
    }
    
    /// Resolve (get) an instance of a registered type
    /// - Parameter type: The type to resolve
    /// - Returns: Instance of the type, or nil if not registered
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        guard let factory = factories[key] else {
            print("❌ Failed to resolve dependency: \(key)")
            return nil
        }
        return factory() as? T
    }
    
    /// Clear all registered dependencies (useful for testing)
    func clear() {
        factories.removeAll()
        print("🧹 Cleared all dependencies")
    }
}

// MARK: - Property Wrapper for Injection
/// Property wrapper for easy dependency injection
/// Usage: @Injected private var service: ServiceProtocol
@propertyWrapper
struct Injected<T> {
    let wrappedValue: T
    
    init() {
        guard let value = DIContainer.shared.resolve(T.self) else {
            fatalError("❌ No registered factory for type \(T.self). Did you forget to register it?")
        }
        self.wrappedValue = value
    }
}
