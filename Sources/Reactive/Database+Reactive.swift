//
//  Database+Reactive.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 03/02/2019.
//

#if USE_REACTIVESWIFT
import FirebaseDatabase
import ReactiveSwift



extension Database: ReactiveExtensionsProvider {}

extension Reactive where Base: Database {

	// MARK: Read

	/// Gets the data at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - event: The type of event to listen for
	///   - query: Block generating the query
	/// - Returns: A signal producer of a snapshot and the previous key
	public func get(path: Path,
					event: DataEventType = .value,
					query: ((DatabaseQuery) -> DatabaseQuery)?) -> SignalProducer<(snapshot: DataSnapshot, previousKey: String?), NSError> {

		return SignalProducer { [weak base] observer, _ in

			guard let base = base else { observer.sendCompleted(); return }

			base.get(path: path,
					 event: event,
					 query: query,
					 completed: { observer.send(value: ($0, $1)); observer.sendCompleted() },
					 failed: { observer.send(error: $0) })
		}
	}

	/// Observes data at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - event: The type of event to listen for
	///   - query: Block generating the query
	/// - Returns: A signal producer of a snapshot and the previous key
	public func observe(path: Path,
						event: DataEventType = .value,
						query: ((DatabaseQuery) -> DatabaseQuery)?) -> SignalProducer<(snapshot: DataSnapshot, previousKey: String?), NSError> {

		return SignalProducer { [weak base] observer, lifetime in

			guard let base = base else { observer.sendCompleted(); return }

			let id = base.observe(path: path,
								  event: event,
								  query: query,
								  completed: { observer.send(value: ($0, $1)) },
								  failed: { observer.send(error: $0) })

			lifetime.observeEnded { [weak base] in
				if let base = base {
					path.reference(with: base).removeObserver(withHandle: id)
				}
			}
		}
	}

	/// Observes data changes at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - query: Block generating the query
	/// - Returns: A signal producer of a snapshot changes
	public func observeChanges(path: Path,
							   query: ((DatabaseQuery) -> DatabaseQuery)?) -> SignalProducer<SnapshotChange, NSError> {

		return SignalProducer { [weak base] observer, lifetime in

			guard let base = base else { observer.sendCompleted(); return }

			let ids = base.observeChanges(path: path,
										  query: query,
										  completed: { observer.send(value: $0) },
										  failed: { observer.send(error: $0) })

			lifetime.observeEnded { [weak base] in
				if let base = base {
					let reference = path.reference(with: base)
					ids.forEach { reference.removeObserver(withHandle: $0) }
				}
			}
		}
	}

	/// Observes user's connection status.
	///
	/// - Returns: A signal producer of the connection status
	public func isConnected() -> SignalProducer<Bool, NSError> {

		return SignalProducer { [weak base] observer, lifetime in

			guard let base = base else { observer.sendCompleted(); return }

			let id = base.isConnected(completed: { observer.send(value: $0) },
									  failed: { observer.send(error: $0) })

			lifetime.observeEnded { [weak base] in
				if let base = base {
					let path = Path(path: ".info/connected")!
					path.reference(with: base).removeObserver(withHandle: id)
				}
			}
		}
	}



	// MARK: - Create

	/// Saves data to the given path.
	///
	/// - Parameters:
	///   - data: Data
	///   - path: Path
	///   - whenDisconnected: Wether saving happens only when getting disconnected
	/// - Returns: A signal producer of the identifier of the data that was saved
	public func save(data: Any??,
					 priority: Any?? = nil,
					 path: Path,
					 whenDisconnected: Bool = false) -> SignalProducer<String?, NSError> {

		return SignalProducer { [weak base] observer, _ in

			guard let base = base else { observer.sendCompleted(); return }

			base.save(data: data,
					  priority: priority,
					  path: path,
					  whenDisconnected: whenDisconnected,
					  completed: { observer.send(value: $0); observer.sendCompleted() },
					  failed: { observer.send(error: $0) })
		}
	}

	/// Merges data to existing data.
	/// If no previous data exists, it will save provided data.
	///
	/// - Parameters:
	///   - data: Data
	///   - fields: Fields to be merged
	///   - path: Path
	///   - whenDisconnected: Wether saving happens only when getting disconnected
	/// - Returns: A signal producer of the identifier of the data that was merged
	public func merge(data: [AnyHashable: Any],
					  fields: [AnyHashable]?,
					  path: Path,
					  whenDisconnected: Bool = false) -> SignalProducer<String?, NSError> {

		return SignalProducer { [weak base] observer, _ in

			guard let base = base else { observer.sendCompleted(); return }

			base.merge(data: data,
					   fields: fields,
					   path: path,
					   whenDisconnected: whenDisconnected,
					   completed: { observer.send(value: $0); observer.sendCompleted() },
					   failed: { observer.send(error: $0) })
		}
	}


	// MARK: Delete

	/// Deletes data at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - whenDisconnected: Wether saving happens only when getting disconnected
	/// - Returns: A signal producer of the identifier of the data that was deleted
	public func delete(path: Path,
					   whenDisconnected: Bool = false) -> SignalProducer<String?, NSError> {

		return SignalProducer { [weak base] observer, _ in

			guard let base = base else { observer.sendCompleted(); return }

			base.delete(path: path,
						whenDisconnected: whenDisconnected,
						completed: { observer.send(value: $0); observer.sendCompleted() },
						failed: { observer.send(error: $0) })
		}
	}


	// MARK: - Transaction

	/// Makes changes atomically.
	///
	/// - Parameters:
	///   - path: Path
	///   - transaction: A block for mutating the data at the given path
	///   - sendIntermediateEvents : If true, intermediate states going through transaction will raise data events
	/// - Returns: A signal producer of the snapshot after transaction and wether the transaction was commited
	public func runTransaction(path: Path,
							   transaction: @escaping (inout MutableData) throws -> Void,
							   sendIntermediateEvents: Bool = false) -> SignalProducer<(snapshot: DataSnapshot?, isCommitted: Bool), NSError> {

		return SignalProducer { [weak base] observer, _ in

			guard let base = base else { observer.sendCompleted(); return }

			base.runTransaction(path: path,
								transaction: transaction,
								sendIntermediateEvents: sendIntermediateEvents,
								completed: { observer.send(value: ($0, $1)); observer.sendCompleted() },
								failed: { observer.send(error: $0) })
		}
	}


	// MARK: - Presence

	/// Cancels any operations that are set to run when being disconnected.
	///
	/// - Parameters:
	///   - path: Path
	/// - Returns: A signal producer of the identifier where operations were canceled
	public func cancel(path: Path) -> SignalProducer<String?, NSError> {

		return SignalProducer { [weak base] observer, _ in

			guard let base = base else { observer.sendCompleted(); return }

			base.delete(path: path,
						completed: { observer.send(value: $0); observer.sendCompleted() },
						failed: { observer.send(error: $0) })
		}
	}

}

#endif
