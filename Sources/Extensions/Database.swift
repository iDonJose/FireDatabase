//
//  Database.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 03/02/2019.
//

import FirebaseDatabase



extension Database {

	// MARK: Read

	/// Gets the data at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - event: The type of event to listen for
	///   - query: Block generating the query
	///   - completed: Completion callback
	///   - failed: Failure callback
	public func get(path: Path,
					event: DataEventType = .value,
					query: ((DatabaseQuery) -> DatabaseQuery)?,
					completed: @escaping (_ snapshot: DataSnapshot, _ previousKey: String?) -> Void,
					failed: @escaping (NSError) -> Void) {

		var reference: DatabaseQuery = path.reference(with: self)

		if let query = query { reference = query(reference) }

		reference.observeSingleEvent(of: event,
									 andPreviousSiblingKeyWith: completed,
									 withCancel: { failed($0 as NSError) })
	}

	/// Observes data at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - event: The type of event to listen for
	///   - query: Block generating the query
	///   - completed: Completion callback
	///   - failed: Failure callback
	/// - Returns: An identifier for canceling observation
	public func observe(path: Path,
						event: DataEventType = .value,
						query: ((DatabaseQuery) -> DatabaseQuery)?,
						completed: @escaping (_ snapshot: DataSnapshot, _ previousKey: String?) -> Void,
						failed: @escaping (NSError) -> Void) -> UInt {

		var reference: DatabaseQuery = path.reference(with: self)

		if let query = query { reference = query(reference) }

		return reference.observe(event,
								 andPreviousSiblingKeyWith: completed,
								 withCancel: { failed($0 as NSError) })
	}

	/// Observes data changes at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - query: Block generating the query
	///   - completed: Completion callback
	///   - failed: Failure callback
	/// - Returns: An array of identifiers for canceling observations
	public func observeChanges(path: Path,
							   query: ((DatabaseQuery) -> DatabaseQuery)?,
							   completed: @escaping (SnapshotChange) -> Void,
							   failed: @escaping (NSError) -> Void) -> [UInt] {

		var ids = [UInt]()

		ids.append(observe(path: path,
						   event: .childRemoved,
						   query: query,
						   completed: { completed(.delete($0, previousKey: $1)) },
						   failed: failed))

		ids.append(observe(path: path,
						   event: .childAdded,
						   query: query,
						   completed: { completed(.insert($0, previousKey: $1)) },
						   failed: failed))

		ids.append(observe(path: path,
						   event: .childMoved,
						   query: query,
						   completed: { completed(.move($0, previousKey: $1)) },
						   failed: failed))

		ids.append(observe(path: path,
						   event: .childChanged,
						   query: query,
						   completed: { completed(.update($0, previousKey: $1)) },
						   failed: failed))

		return ids
	}

	/// Observes user's connection status.
	///
	/// - Parameters:
	///   - completed: Completion callback
	///   - failed: Failure callback
	/// - Returns: An identifier for canceling observation
	public func isConnected(completed: @escaping (Bool) -> Void,
							failed: @escaping (NSError) -> Void) -> UInt {

		let path = Path(path: ".info/connected")!

		let completed: (DataSnapshot, String?) -> Void = { snapshot, _ in
			let isConnected = snapshot.exists()
				&& (snapshot.value as? Bool) == true
			completed(isConnected)
		}


		return observe(path: path,
					   query: nil,
					   completed: completed,
					   failed: failed)
	}



	// MARK: - Create

	/// Saves data to the given path.
	///
	/// - Parameters:
	///   - data: Data
	///   - path: Path
	///   - whenDisconnected: Wether saving happens only when getting disconnected
	///   - completed: Completion callback
	///   - failed: Failure callback
	public func save(data: Any??,
					 priority: Any?? = nil,
					 path: Path,
					 whenDisconnected: Bool = false,
					 completed: @escaping (String?) -> Void,
					 failed: @escaping (NSError) -> Void) {

		let reference = path.reference(with: self)

		let _completed: (Error?, DatabaseReference) -> Void = { error, reference in
			if let error = error as NSError? { failed(error) }
			else { completed(reference.key) }
		}


		if !whenDisconnected {
			if let data = data, let priority = priority {
				reference.setValue(data, andPriority: priority, withCompletionBlock: _completed)
			}
			else if let priority = priority {
				reference.setPriority(priority, withCompletionBlock: _completed)
			}
			else if let data = data {
				reference.setValue(data, withCompletionBlock: _completed)
			}
			else {
				assert(false, "At least one of the two data or priority must be provided when saving")
				completed(nil)
			}
		}
		else {
			if let data = data, let priority = priority {
				reference.onDisconnectSetValue(data, andPriority: priority, withCompletionBlock: _completed)
			}
			else if let data = data {
				reference.onDisconnectSetValue(data, withCompletionBlock: _completed)
			}
			else {
				assert(false, "Data must be provided when saving on disconnection")
				completed(nil)
			}
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
	///   - completed: Completion callback
	///   - failed: Failure callback
	public func merge(data: [AnyHashable: Any],
					  fields: [AnyHashable]?,
					  path: Path,
					  whenDisconnected: Bool = false,
					  completed: @escaping (String?) -> Void,
					  failed: @escaping (NSError) -> Void) {

		let reference = path.reference(with: self)

		let data = fields != nil
			? data.filter { fields!.contains($0.key) }
			: data

		let completed: (Error?, DatabaseReference) -> Void = { error, reference in
			if let error = error as NSError? { failed(error) }
			else { completed(reference.key) }
		}


		if !whenDisconnected {
			reference.updateChildValues(data, withCompletionBlock: completed)
		}
		else {
			reference.onDisconnectUpdateChildValues(data, withCompletionBlock: completed)
		}

	}


	// MARK: Delete

	/// Deletes data at the given path.
	///
	/// - Parameters:
	///   - path: Path
	///   - whenDisconnected: Wether saving happens only when getting disconnected
	///   - completed: Completion callback
	///   - failed: Failure callback
	public func delete(path: Path,
					   whenDisconnected: Bool = false,
					   completed: @escaping (String?) -> Void,
					   failed: @escaping (NSError) -> Void) {

		let reference = path.reference(with: self)

		let completed: (Error?, DatabaseReference) -> Void = { error, reference in
			if let error = error as NSError? { failed(error) }
			else { completed(reference.key) }
		}


		if !whenDisconnected {
			reference.removeValue(completionBlock: completed)
		}
		else {
			reference.onDisconnectRemoveValue(completionBlock: completed)
		}

	}


	// MARK: - Transaction

	/// Makes changes atomically.
	///
	/// - Parameters:
	///   - path: Path
	///   - transaction: A block for mutating the data at the given path
	///   - sendIntermediateEvents : If true, intermediate states going through transaction will raise data events
	///   - completed: Completion callback
	///   - failed: Failure callback
	public func runTransaction(path: Path,
								  transaction: @escaping (inout MutableData) throws -> Void,
								  sendIntermediateEvents: Bool = false,
								  completed: @escaping (_ snapshot: DataSnapshot?, _ isCommitted: Bool) -> Void,
								  failed: @escaping (NSError) -> Void) {

		let reference = path.reference(with: self)

		let _transaction: (MutableData) -> TransactionResult = { data in
			do {
				var data = data
				try transaction(&data)
				return .success(withValue: data)
			}
			catch {
				return .abort()
			}
		}

		let completion: (Error?, Bool, DataSnapshot?) -> Void = { error, isCommitted, snapshot in
			if let error = error as NSError? { failed(error) }
			else { completed(snapshot, isCommitted) }
		}


		reference.runTransactionBlock(_transaction, andCompletionBlock: completion, withLocalEvents: sendIntermediateEvents)

	}


	// MARK: - Presence

	/// Cancels any operations that are set to run when being disconnected.
	///
	/// - Parameters:
	///   - path: Path
	///   - completed: Completion callback
	///   - failed: Failure callback
	public func cancel(path: Path,
					   completed: @escaping (String?) -> Void,
					   failed: @escaping (NSError) -> Void) {

		let reference = path.reference(with: self)

		reference.cancelDisconnectOperations { error, reference in
			if let error = error as NSError? { failed(error) }
			else { completed(reference.key) }
		}

	}

}
