import Foundation

// MARK: - DIContainerProtocol

protocol DIContainerProtocol {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func resolve<T>(_ type: T.Type) -> T?
}

// MARK: - DIContainer

class DIContainer: DIContainerProtocol {
    static let shared = DIContainer()
    
    private var factories: [String: () -> Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        guard let factory = factories[key] else {
            return nil
        }
        return factory() as? T
    }
    
    func clear() {
        factories.removeAll()
    }
}

// MARK: - Property Wrapper for Injection

@propertyWrapper
struct Injected<T> {
    let wrappedValue: T
    
    init() {
        guard let value = DIContainer.shared.resolve(T.self) else {
            fatalError("No registered factory for type \(T.self)")
        }
        self.wrappedValue = value
    }
}
