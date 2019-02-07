//
//  SnapshotChange.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 04/02/2019.
//

import FirebaseDatabase
import SwiftXtend



public enum SnapshotChange {

	case delete(DataSnapshot, previousKey: String?)
	case insert(DataSnapshot, previousKey: String?)
	case move(DataSnapshot, previousKey: String?)
	case update(DataSnapshot, previousKey: String?)



	public var snapshot: DataSnapshot {
		switch self {
		case let .delete(snapshot, _),
			 let .insert(snapshot, _),
			 let .move(snapshot, _),
			 let .update(snapshot, _):
			return snapshot
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
