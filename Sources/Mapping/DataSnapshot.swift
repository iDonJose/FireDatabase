//
//  DataSnapshot.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 03/02/2019.
//

import FirebaseDatabase
import SwiftXtend



extension DataSnapshot {

	/// Maps snapshot to the provided type.
	///
	/// - Parameter type: Output type
	/// - Returns: Either the decoded type or an error if mapping failed
	public func map<T: Identifiable & Decodable>(_ type: T.Type) -> Either<T?, NSError> where T.Identifier == String {

		guard exists() else { return .init(nil) }
		guard let data = value,
			!NSNull().isEqual(data) else { return .init(nil) }

		do {
			let data = try JSONSerialization.data(withJSONObject: data)

			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .millisecondsSince1970

			var value = try decoder.decode(type, from: data)
			value.id = key

			return .init(value)
		}
		catch let error as NSError {
			return .init(error)
		}

	}

}
