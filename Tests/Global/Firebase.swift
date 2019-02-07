//
//  Firebase.swift
//  FireDatabase-Tests-iOS
//
//  Created by José Donor on 04/02/2019.
//

import FirebaseCore
import FirebaseDatabase
import Foundation



private final class Mock {}

private let app: FirebaseApp = {

	let path = Bundle(for: Mock.self)
		.path(forResource: "GoogleService-Info", ofType: "plist")!

	let options = FirebaseOptions(contentsOfFile: path)!
	FirebaseApp.configure(options: options)

	return FirebaseApp.app()!
}()


let database: Database = {

	let database = Database.database(app: app)
	database.callbackQueue = DispatchQueue(label: "Database",
										   qos: .default)
	database.isPersistenceEnabled = true

	return database
}()
