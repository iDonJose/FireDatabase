import FirebaseCore
import FirebaseDatabase
import FireDatabase
import Foundation
import ReactiveSwift
import Result
import SwiftXtend


// Setup

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


struct Message: Identifiable, Codable {

    var id: String = ""

    var sender: String = ""
    var receiver: String = ""
    var text: String = ""
    var date: Double = 0

    init(id: String) {
        self.id = id
    }

    init(id: String = "",
         sender: String = "",
         receiver: String = "",
         text: String = "",
         date: Double = 0) {
        self.id = id
        self.sender = sender
        self.receiver = receiver
        self.text = text
        self.date = date
    }


    func data() throws -> [String: Any] {

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        let encoded = try encoder.encode(self)
        let data = try JSONSerialization.jsonObject(with: encoded)

        if let data = data as? [String: Any] {
            return data
        }
        else {
            let userInfo = [
                NSLocalizedFailureReasonErrorKey: "Failed to encode \(type(of: self)) to a dictionary [String: Any]",
                NSLocalizedDescriptionKey: "\(type(of: self)) is not encodable to a data of type [String: Any]"
            ]
            throw NSError(domain: "Tests", code: 1, userInfo: userInfo)
        }

    }

}



/*:
 # `FireDatabase`
 */

let messages = Path(path: "messages")!


/*:
 ## `isConnected()`
 Observes users connection status.
 */

// Checks connection

database.reactive
    .isConnected()
    .flatMapError { _ in SignalProducer.empty }
    .startWithValues { print("Connected", $0 ? "✅" : "⛔️") }


/*:
 ## `observeChanges(path:query:)`
 Observes and filters data changes at the given path.
 > See also `get(path:event:query:)`, `observe(path:event:query:)`.

 ## `mapChange(of:)`
 Converts change snapshots to an array of changes.
 > See also `map(_:)`, `mapArray(of:)`, `mapSet(of:)`.
 */

// Observes all my messages

let disposable_1 = database.reactive
    .observeChanges(path: messages,
                    query: { $0.queryOrdered(byChild: "receiver").queryEqual(toValue: "me") })
    .mapChanges(of: Message.self)
    .flatMapError { _ in SignalProducer.empty }
    .startWithValues { if let change = $0 { print("You received a new message", change) } }

// Observes messages that I send

let disposable_2 = database.reactive
    .observeChanges(path: messages,
                    query: { $0.queryOrdered(byChild: "receiver").queryEqual(toValue: "friend") })
    .mapChanges(of: Message.self)
    .flatMapError { _ in SignalProducer.empty }
    .startWithValues { if let change = $0 { print("You have sent a message", change) } }


/*:
 ## `save(data:path:whenDisconnected:)`
 Saves data at the given path.
 Can be done on disconnection.
 */

// Creates a new message from friend

database.reactive
    .save(data: Message(sender: "friend",
                        receiver: "me",
                        text: "👋 hey buddy",
                        date: 1).data(),
          path: messages.newChild())
    .wait()

// Answers my friend with a new message

database.reactive
    .save(data: Message(sender: "me",
                        receiver: "friend",
                        text: "Hi ! Do you time for a ☕️ ?",
                        date: 2).data(),
          path: messages.child(withId: "my message"))
    .wait()


/*:
 ## `merge(data:fields:path:whenDisconnected:)`
 Merges data to existing data.
 Can be done on disconnection.
 */

database.reactive
    .merge(data: Message(sender: "me",
                         receiver: "friend",
                         text: "Hi ! Do you time to 🏃‍♂️ ?",
                         date: 3).data(),
           fields: ["text", "date"],
           path: messages.child(withId: "my message"))
    .wait()


/*:
 ## `delete(path:whenDisconnected:)`
 Deletes data at the given path.
 Can be done on disconnection.
 */

// Cleans up every messages

disposable_1.dispose()
disposable_2.dispose()

database.reactive
    .delete(path: messages)
    .wait()

print("Messages were cleaned up")


//: < [Summary](Summary) | [Next](@next) >
