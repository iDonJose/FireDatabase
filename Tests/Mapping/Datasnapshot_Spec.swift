//
//  Datasnapshot_Spec.swift
//  FireDatabase-Tests-iOS
//
//  Created by José Donor on 04/02/2019.
//

// swiftlint:disable force_try

import FirebaseDatabase
@testable import FireDatabase
import Nimble
import Quick



class DataSnapshot_Spec: QuickSpec {
	override func spec() {

		AsyncDefaults.Timeout = 3

		var collection: Path!


		beforeEach {

			collection = Path(path: "documents")!

			waitUntil(timeout: 5) { done in
				database.delete(path: collection,
								completed: { _ in done() },
								failed: { _ in })
			}

		}



		describe("DataSnapshot") {

			describe("map(_:)") {
				it("maps snapshot to the given type") {

					let path = collection.child(withId: "id")

					var car = Car.default
					let data = try! car.data()
					car.id = "id"

					waitUntil(timeout: 3) { done in
						database.save(data: data,
									  path: path,
									  completed: { _ in done() },
									  failed: { _ in })
					}


					var mapSucceeded = false

					let completed: (DataSnapshot, String?) -> Void = { snapshot, _ in
						if let value = snapshot.map(Car.self).a,
							let mappedCar = value {

							mapSucceeded = mappedCar == car
						}
					}

					database.get(path: path,
								 query: nil,
								 completed: completed,
								 failed: Error.catchError)

					expect(mapSucceeded).toEventually(beTrue())

				}
			}

		}

	}
}
