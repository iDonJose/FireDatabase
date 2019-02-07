//
//  Path.swift
//  FireDatabase-iOS
//
//  Created by José Donor on 03/02/2019.
//

import FirebaseDatabase



public struct Path: CustomStringConvertible {

	/// Components forming the path
	public let components: [Component]



	// MARK: - Initialize

	/// Create a path from a String.
	/// For example, "/countries/france/cities/" for a path to a collection,
	/// Or "/countries/france/cities/*" for a new city.
	public init?(path: String) {

		let pathComponents = path.split(separator: "/").map { String($0) }

		guard
			!pathComponents.isEmpty
				&& !pathComponents.contains(where: { $0.isEmpty }) else {

					if pathComponents.isEmpty { assert(true, "Provided path \(path) is empty") }
					else { assert(true, "Provided path \(path) contains empty components") }

					return nil
		}

		self.init(pathComponents: pathComponents)
	}


	public init?(pathComponents components: String...) {
		self.init(pathComponents: components)
	}

	public init(pathComponents components: [String]) {

		self.components = components
			.map {
				if $0 == "*" { return .newChild }
				else { return .child($0) }
			}
	}

	init(components: [Component]) {
		self.components = components
	}



	// MARK: - Methods

	public func reference(with database: Database) -> DatabaseReference {

		let reference = database.reference()

		return components
			.reduce(reference, { reference, component in
				switch component {
				case .newChild:
					return reference.childByAutoId()
				case let .child(value):
					return reference.child(value)
				}
			})
	}

	/// Adds a new child to the path
	public func newChild() -> Path {

		var components = self.components
		components.append(.newChild)

		return Path(components: components)
	}

	/// Adds a specific child to the path
	public func child(withId id: String) -> Path {

		var components = self.components
		components.append(.child(id))

		return Path(components: components)
	}


	/// Description
	public var description: String {
		return components.map { $0.value }.joined(separator: "/")
	}


	public static func + (lhs: Path, rhs: String) -> Path {
		if rhs == "*" { return lhs.newChild() }
		else { return lhs.child(withId: rhs) }
	}



	// MARK: - Component
	public enum Component {

		case newChild
		case child(String)


		var value: String {
			switch self {
			case .newChild:
				return "*"
			case let .child(value):
				return value
			}
		}

	}

}
