//
//  Database+Reactive_Spec.swift
//  FireDatabase-Tests-iOS
//
//  Created by José Donor on 04/02/2019.
//

// swiftlint:disable force_cast

import FirebaseCore
import FirebaseDatabase
@testable import FireDatabase
import Nimble
import Quick
import ReactiveSwift



class Database_Reactive_Spec: QuickSpec {
	override func spec() {

		AsyncDefaults.Timeout = 3

		var id: String!
		var data: [String: Any]!
		var collection: Path!


		beforeEach {

			id = "id"

			data = [
				"string": "some text",
				"boolean": true,
				"number": 3,
				"array": [1, 2, 3],
				"dictionary": ["key": "value"]
			]

			collection = Path(path: "documents")!

			let result = database.reactive.delete(path: collection).wait()

			assert(result.error == nil, "Failed deleting all data")

		}


		describe("Database+Reactive") {

			describe("get(path:query:)") {
				it("gets data at the given path") {

					let path = collection.child(withId: id)

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in done() },
									  failed: { _ in })
					}

					var dataExists = false

					database.reactive
						.get(path: path,
							 query: nil)
						.catchError()
						.startWithValues { snapshot, _ in dataExists = (snapshot.value as? [String: Any] ?? [:]) == data }

					expect(dataExists).toEventually(beTrue())

				}
			}

			describe("observe(path:query:)") {
				it("observes data at the given path") {

					let path = collection.child(withId: id)

					let values: [[String: Any]?] = [nil, data]
					let condition = SequenceCondition(values,
													  areEqual: { $0 == $1 })

					database.reactive
						.observe(path: path,
							 query: nil)
						.catchError()
						.startWithValues { snapshot, _ in condition.send(snapshot.value as? [String: Any]) }


					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						database.save(data: data,
									  path: path,
									  completed: { _ in },
									  failed: { _ in })
					}

					expect(condition.result).toEventually(beTrue())

				}
			}

			describe("observeChanges(path:query:)") {
				it("observes data changes at the given path") {

					let path = collection.child(withId: id)

					let values: [[String: Any]?] = [data]
					let condition = SequenceCondition(values,
													  areEqual: { $0 == $1 })

					_ = database.reactive
						.observeChanges(path: collection,
												query: nil)
						.catchError()
						.startWithValues { change in if case .insert = change { condition.send(change.snapshot.value as? [String: Any]) } }

					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						database.save(data: data,
									  path: path,
									  completed: { _ in },
									  failed: { _ in })
					}

					expect(condition.result).toEventually(beTrue())

				}
			}


			describe("save(data:path:)") {
				it("saves data at the given path") {

					let path = collection.child(withId: id)

					let wasSaved = database.reactive
						.save(data: data,
							  path: path)
						.catchError()
						.wait().value != nil

					var dataExists = false

					database.get(path: path,
								 query: nil,
								 completed: { snapshot, _ in dataExists = (snapshot.value as? [String: Any] ?? [:]) == data },
								 failed: Error.catchError)

					expect(wasSaved).toEventually(beTrue())
					expect(dataExists).toEventually(beTrue())

				}
			}

			describe("merge(data:fields:path:)") {
				it("merges data to an existing one") {

					let path = collection.child(withId: id)

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in done() },
									  failed: { _ in })
					}

					let wasMerged = database.reactive
						.merge(data: ["new field": 10],
							   fields: ["new field"],
							   path: path)
						.wait().value != nil

					var newData = data!
					newData["new field"] = 10

					var dataIsUpToDate = false

					database.get(path: path,
								 query: nil,
								 completed: { snapshot, _ in dataIsUpToDate = (snapshot.value as? [String: Any] ?? [:]) == newData },
								 failed: Error.catchError)

					expect(wasMerged).toEventually(beTrue())
					expect(dataIsUpToDate).toEventually(beTrue())

				}
			}

			describe("delete(path:)") {
				it("deletes data at the given path") {

					let path = collection.child(withId: id)

					var wasSaved = false

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in wasSaved = true; done() },
									  failed: { _ in })
					}

					var wasDeleted = false

					database.reactive
						.delete(path: path)
						.catchError()
						.startWithValues { _ in wasDeleted = true }

					var dataIsDeleted = false

					database.get(path: path,
								 query: nil,
								 completed: { snapshot, _ in dataIsDeleted = snapshot.value == nil || NSNull().isEqual(snapshot.value!) },
								 failed: Error.catchError)

					expect(wasSaved).toEventually(beTrue())
					expect(wasDeleted).toEventually(beTrue())
					expect(dataIsDeleted).toEventually(beTrue())

				}
			}


			describe("runTransaction(transaction:)") {
				it("makes changes atomically") {

					let path = collection.child(withId: id)

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in done() },
									  failed: { _ in })
					}


					let transaction: (inout MutableData) throws -> Void = { data in
						var dictionary = data.value as! [String: Any]
						dictionary["new field"] = 10
						data.value = dictionary
					}

					var didRanTransaction = false

					_ = database.reactive
						.runTransaction(path: path,
										transaction: transaction)
						.catchError()
						.on(value: { _, isCommitted in didRanTransaction = isCommitted })
						.wait()

					var newData = data!
					newData["new field"] = 10

					var dataIsUpToDate = false

					database.get(path: path,
								 query: nil,
								 completed: { snapshot, _ in dataIsUpToDate = (snapshot.value as? [String: Any] ?? [:]) == newData },
								 failed: Error.catchError)


					expect(didRanTransaction).toEventually(beTrue())
					expect(dataIsUpToDate).toEventually(beTrue())

				}
			}

			describe("cancel(path:)") {
				it("cancels operations run when disconnected") {

					let path = collection.child(withId: id)

					database.save(data: data,
								  path: path,
								  whenDisconnected: true,
								  completed: { _ in },
								  failed: { _ in })

					var wasCanceled = false

					database.reactive
						.cancel(path: path)
						.catchError()
						.startWithValues { _ in wasCanceled = true }

					expect(wasCanceled).toEventually(beTrue())

				}
			}

		}

	}
}
