//
//  SignalProducerProtocol_Spec.swift
//  FireDatabase-Tests-iOS
//
//  Created by José Donor on 04/02/2019.
//

// swiftlint:disable force_try

import FirebaseDatabase
@testable import FireDatabase
import Nimble
import Quick



class SignalProducerProtocol_Spec: QuickSpec {
	override func spec() {

		AsyncDefaults.Timeout = 3

		var collection: Path!
		var path: Path!
		var id: String!


		beforeEach {

			collection = Path(path: "documents")!
			id = "id"
			path = collection.child(withId: id)

			waitUntil(timeout: 5) { done in
				database.delete(path: collection,
								completed: { _ in done() },
								failed: { _ in })
			}

			waitUntil(timeout: 3) { done in
				database.save(data: try! Car.default.data(),
							  path: path,
							  completed: { _ in done() },
							  failed: { _ in })
			}

			waitUntil(timeout: 3) { done in
				database.save(data: try! Car.twingo.data(),
							  path: collection.child(withId: "twingo"),
							  completed: { _ in done() },
							  failed: { _ in })
			}

		}



		describe("SignalProducerProtocol") {

			describe("mapData()") {
				it("maps document snapshot to a dictionary") {

					var mapSucceeded = false

					database.reactive
						.get(path: path,
							 query: nil)
						.mapData()
						.catchError()
						.startWithValues {
							if let value = $0 {
								mapSucceeded = try! value.id == id
									&& value.data as? [String: Any] == Car.default.data()
							}
						}

					expect(mapSucceeded).toEventually(beTrue())

				}
			}

			describe("map(_:)") {
				it("maps snapshot to the given type") {

					var car = Car.default
					car.id = id

					var mapSucceeded = false

					database.reactive
						.get(path: path,
							 query: nil)
						.map(Car.self)
						.catchError()
						.startWithValues { mapSucceeded = $0.value == car }

					expect(mapSucceeded).toEventually(beTrue())

				}
			}

			describe("mapArray(of:)") {
				it("maps snapshot to an array of the given types") {

					var car = Car.default
					car.id = id

					var twingo = Car.twingo
					twingo.id = "twingo"

					let expectedData = [car, twingo]

					var mapSucceeded = false

					database.reactive
						.get(path: collection,
							 query: nil)
						.mapArray(of: Car.self)
						.catchError()
						.startWithValues { mapSucceeded = $0.values == expectedData }

					expect(mapSucceeded).toEventually(beTrue())

				}
			}

			describe("mapChanges(of:)") {
				it("maps snapshot to an array of changes") {

					var car = Car.default
					car.id = id

					var twingo = Car.twingo
					twingo.id = "twingo"

					let values = [car, twingo]
					let condition = SequenceCondition<Car>(values,
														   areEqual: { $0 == $1 })

					database.reactive
						.observeChanges(path: collection,
										query: nil)
						.mapChanges(of: Car.self)
						.catchError()
						.skipNil()
						.startWithValues { change in
							if case .insert = change {
								condition.send(change.value)
							}
						}

					expect(condition.result).toEventually(beTrue())

				}
			}

		}

	}
}
