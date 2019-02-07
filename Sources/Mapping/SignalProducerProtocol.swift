//
//  SignalProducerProtocol.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 04/02/2019.
//

#if USE_REACTIVESWIFT
import FirebaseDatabase
import ReactiveSwift
import Result
import SwiftXtend



extension SignalProducerProtocol where Value == (snapshot: DataSnapshot, previousKey: String?), Error == NSError {

	/// Maps snapshots to its identifier and data.
	///
	/// - Returns: A signal
	public func mapData() -> SignalProducer<(id: String, data: Any?, previousKey: String?)?, Error> {
		return producer.lift { $0.mapData() }
	}

	/// Maps snapshots to the given type.
	///
	/// - Returns: A signal
	public func map<T: Identifiable & Decodable>(_ type: T.Type)
		-> SignalProducer<(value: T?, previousKey: String?), Error> where T.Identifier == String {

			return producer.lift { $0.map(type) }
	}

	/// Maps snapshots to an array of the given types.
	///
	/// - Returns: A signal
	public func mapArray<T: Identifiable & Decodable>(of type: T.Type)
		-> SignalProducer<(values: [T], previousKey: String?), Error> where T.Identifier == String {

			return producer.lift { $0.mapArray(of: type) }
	}

	/// Maps snapshots to a set of the given types.
	///
	/// - Returns: A signal
	public func mapSet<T: Identifiable & Decodable>(of type: T.Type)
		-> SignalProducer<(values: Set<T>, previousKey: String?), Error> where T.Identifier == String {

			return producer.lift { $0.mapSet(of: type) }
	}

}


extension SignalProducerProtocol where Value == SnapshotChange, Error == NSError {

	/// Maps change snapshots to an array of changes.
	///
	/// - Returns: A signal
	public func mapChanges<T: Identifiable & Decodable>(of type: T.Type)
		-> SignalProducer<Change<T>?, Error> where T.Identifier == String {

			return producer.lift { $0.mapChanges(of: type) }
	}

}
#endif
