import Combine
import Foundation

// MARK: - ViewModelProtocol
/// Base protocol for all ViewModels - establishes common patterns
/// This ensures consistency across all ViewModels in the app
protocol ViewModelProtocol: ObservableObject {
    var cancellables: Set<AnyCancellable> { get set }
    func onAppear()
    func onDisappear()
}

// MARK: - BaseViewModel
/// Base class for all ViewModels - provides common functionality
/// Handles memory management and lifecycle methods
class BaseViewModel: ViewModelProtocol {
    var cancellables = Set<AnyCancellable>()
    
    func onAppear() {
        // Override in subclasses for setup logic
        // Called when view appears
    }
    
    func onDisappear() {
        // Cancel all subscriptions to prevent memory leaks
        // This is crucial for proper memory management
        cancellables.removeAll()
    }
    
    deinit {
        // Final cleanup - ensures no retain cycles
        cancellables.removeAll()
        print("🗑️ \(String(describing: type(of: self))) deallocated")
    }
}

// MARK: - Publisher Extensions
/// Extensions to make Combine more convenient to use
extension Publisher {
    /// Maps values asynchronously - bridges async/await with Combine
    /// Very useful for modern iOS development
    func asyncMap<T>(
        _ transform: @escaping (Output) async -> T
    ) -> Publishers.FlatMap<Future<T, Never>, Self> {
        flatMap { value in
            Future { promise in
                Task {
                    let result = await transform(value)
                    promise(.success(result))
                }
            }
        }
    }
}

/// Extension for UI updates on main thread
/// Essential for SwiftUI state updates
extension Publisher where Self.Failure == Never {
    func receiveOnMainQueue() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
}
