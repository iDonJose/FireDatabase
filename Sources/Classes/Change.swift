//
//  Change.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 04/02/2019.
//

import SwiftXtend



public enum Change<T: Identifiable & Decodable> where T.Identifier == String {

	case delete(T, previousKey: String?)
	case insert(T, previousKey: String?)
	case move(T, previousKey: String?)
	case update(T, previousKey: String?)


	// MARK: - Initialize

	public init?(change: SnapshotChange,
				 ofType type: T.Type) throws {

		let snapshot = change.snapshot

		let either = snapshot.map(type)

		if let error = either.b { throw error }
		guard let _value = either.a,
			let value = _value else { return nil }

		let previousKey = change.previousKey

		switch change {
		case .delete:
			self = .delete(value, previousKey: previousKey)
		case .insert:
			self = .insert(value, previousKey: previousKey)
		case .move:
			self = .move(value, previousKey: previousKey)
		case .update:
			self = .update(value, previousKey: previousKey)
		}

	}


	public var value: T {
		switch self {
		case let .delete(value, _),
			 let .insert(value, _),
			 let .move(value, _),
			 let .update(value, _):
			return value
		}
	}

	public var previousKey: String? {
		switch self {
		case let .delete(_, key),
			 let .insert(_, key),
			 let .move(_, key),
			 let .update(_, key):
			return key
		}
	}

}
