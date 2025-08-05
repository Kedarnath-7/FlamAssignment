import Combine
import Foundation

// MARK: - ViewModelProtocol
/// Base protocol for all ViewModels
protocol ViewModelProtocol: ObservableObject {
    var cancellables: Set<AnyCancellable> { get set }
    func onAppear()
    func onDisappear()
}

// MARK: - BaseViewModel
/// Base class for all ViewModels - provides common functionality
class BaseViewModel: ViewModelProtocol {
    var cancellables = Set<AnyCancellable>()
    
    func onAppear() {
        // Default implementation does nothing
        // Subclasses can override to perform actions when view appears
    }
    
    func onDisappear() {
        // Cancel all subscriptions to prevent memory leaks
        cancellables.removeAll()
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Publisher Extensions
extension Publisher {
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

extension Publisher where Self.Failure == Never {
    func receiveOnMainQueue() -> Publishers.ReceiveOn<Self, DispatchQueue> {
        receive(on: DispatchQueue.main)
    }
}
