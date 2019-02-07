//
//  Database_Spec.swift
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



class Database_Spec: QuickSpec {
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

			waitUntil(timeout: 5) { done in
				database.delete(path: collection,
								completed: { _ in done() },
								failed: { _ in })
			}

		}


		describe("Database") {

			describe("get(path:query:completed:failed:)") {
				it("gets data at the given path") {

					let path = collection.child(withId: id)

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in done() },
									  failed: { _ in })
					}

					var dataExists = false

					database.get(path: path,
								 query: nil,
								 completed: { snapshot, _ in dataExists = (snapshot.value as? [String: Any] ?? [:]) == data },
								 failed: Error.catchError)

					expect(dataExists).toEventually(beTrue())

				}
			}

			describe("observe(path:query:completed:failed:)") {
				it("observes data at the given path") {

					let path = collection.child(withId: id)

					let values: [[String: Any]?] = [nil, data]
					let condition = SequenceCondition(values,
													  areEqual: { $0 == $1 })

					_ = database.observe(path: path,
										 query: nil,
										 completed: { snapshot, _ in condition.send(snapshot.value as? [String: Any]) },
										 failed: Error.catchError)

					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						database.save(data: data,
									  path: path,
									  completed: { _ in },
									  failed: { _ in })
					}

					expect(condition.result).toEventually(beTrue())

				}
			}

			describe("observeChanges(path:query:completed:failed:)") {
				it("observes data changes at the given path") {

					let path = collection.child(withId: id)

					let values: [[String: Any]?] = [data]
					let condition = SequenceCondition(values,
													  areEqual: { $0 == $1 })

					_ = database.observeChanges(path: collection,
												query: nil,
												completed: { change in if case .insert = change { condition.send(change.snapshot.value as? [String: Any]) } },
												failed: Error.catchError)

					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
						database.save(data: data,
									  path: path,
									  completed: { _ in },
									  failed: { _ in })
					}

					expect(condition.result).toEventually(beTrue())

				}
			}


			describe("save(data:path:completed:failed:)") {
				it("saves data at the given path") {

					let path = collection.child(withId: id)

					var wasSaved = false

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in wasSaved = true; done() },
									  failed: { _ in })
					}

					var dataExists = false

					database.get(path: path,
								 query: nil,
								 completed: { snapshot, _ in dataExists = (snapshot.value as? [String: Any] ?? [:]) == data },
								 failed: Error.catchError)

					expect(wasSaved).toEventually(beTrue())
					expect(dataExists).toEventually(beTrue())

				}
			}

			describe("merge(data:fields:path:completed:failed:)") {
				it("merges data to an existing one") {

					let path = collection.child(withId: id)

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in done() },
									  failed: { _ in })
					}

					var wasMerged = false

					waitUntil(timeout: 3) { done in
						database.merge(data: ["new field": 10],
									   fields: ["new field"],
									   path: path,
									   completed: { _ in wasMerged = true; done() },
									   failed: { _ in })
					}

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

			describe("delete(path:completed:failed:)") {
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

					database.delete(path: path,
									completed: { _ in wasDeleted = true },
									failed: { _ in })

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


			describe("runTransaction(transaction:completed:failed:)") {
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

					waitUntil(timeout: 3) { done in
						database.runTransaction(path: path,
												transaction: transaction,
												completed: { _, isCommitted in didRanTransaction = isCommitted; done() },
												failed: Error.catchError)
					}

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

			describe("cancel(path:completed:failed:)") {
				it("cancels operations run when disconnected") {

					let path = collection.child(withId: id)

					database.save(data: data,
								  path: path,
								  whenDisconnected: true,
								  completed: { _ in },
								  failed: { _ in })

					var wasCanceled = false

					database.cancel(path: path,
									completed: { _ in wasCanceled = true },
									failed: { _ in })

					expect(wasCanceled).toEventually(beTrue())

				}
			}

		}

	}

}
