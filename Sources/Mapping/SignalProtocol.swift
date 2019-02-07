//
//  SignalProtocol.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 03/02/2019.
//

#if USE_REACTIVESWIFT
import FirebaseDatabase
import ReactiveSwift
import Result
import SwiftXtend



extension SignalProtocol where Value == (snapshot: DataSnapshot, previousKey: String?), Error == NSError {

	/// Maps snapshots to its identifier and data.
	///
	/// - Returns: A signal
	public func mapData() -> Signal<(id: String, data: Any?, previousKey: String?)?, Error> {

		return signal.map { $0 != nil ? ($0!.key, $0!.value, $1) : nil }
	}

	/// Maps snapshots to the given type.
	///
	/// - Returns: A signal
	public func map<T: Identifiable & Decodable>(_ type: T.Type)
		-> Signal<(value: T?, previousKey: String?), Error> where T.Identifier == String {

			return signal
				.attemptMap { snapshot, previousKey -> Result<(value: T?, previousKey: String?), Error> in

					let either = snapshot.map(type)

					if let value = either.a { return .success((value, previousKey)) }
					else { return .failure(either.b!) }

				}
	}

	/// Maps snapshots to an array of the given types.
	///
	/// - Returns: A signal
	public func mapArray<T: Identifiable & Decodable>(of type: T.Type)
		-> Signal<(values: [T], previousKey: String?), Error> where T.Identifier == String {

			return signal
				.attemptMap { snapshot, previoudKey -> Result<(values: [T], previousKey: String?), Error> in

					guard snapshot.hasChildren()
						else { return .success(([], previoudKey)) }


					var values = [T]()

					let children = snapshot.children.compactMap { $0 as? DataSnapshot }

					for child in children
						where child.exists() && child.value != nil && !NSNull().isEqual(child.value!) {
						do {
							let data = try JSONSerialization.data(withJSONObject: child.value!)

							let decoder = JSONDecoder()
							decoder.dateDecodingStrategy = .millisecondsSince1970

							var value = try decoder.decode(type, from: data)
							value.id = child.key

							values.append(value)
						}
						catch let error as NSError {
							return .failure(error)
						}
					}

					return .success((values, previoudKey))
				}
	}

	/// Maps snapshots to a set of the given types.
	///
	/// - Returns: A signal
	public func mapSet<T: Identifiable & Decodable>(of type: T.Type)
		-> Signal<(values: Set<T>, previousKey: String?), Error> where T.Identifier == String {

			return mapArray(of: type)
				.map { ($0.toSet, $1) }
	}

}


extension SignalProtocol where Value == SnapshotChange, Error == NSError {

	/// Maps query snapshots to an array of changes.
	///
	/// - Returns: A signal
	public func mapChanges<T: Identifiable & Decodable>(of type: T.Type)
		-> Signal<Change<T>?, Error> where T.Identifier == String {

			return signal
				.attemptMap { change -> Result<Change<T>?, Error> in
					do {
						return .success(try Change(change: change, ofType: type))
					}
					catch let error as NSError {
						return .failure(error)
					}
				}
	}

}
#endif
