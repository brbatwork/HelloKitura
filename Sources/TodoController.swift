import Foundation
import Kitura
import LoggerAPI
import SwiftyJSON

// allow cross origin messaging
class AllRemoteOriginMiddleware : RouterMiddleware {
	func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
		response.headers["Access-Control-Allow-Origin"] = "*"
		next()
	}
}

class TodoController {
	let router = Router()
	var list = TodoList()

	func collectJSONBody(request: RouterRequest) ->JSON? {
		guard let body = request.body else {
			Log.error("No Body in Request")
			return nil
		}

		guard case let .json(json) = body else {
			Log.error("Invalid JSON in the body")
			return nil
		}

		return json
	}

	func send(_ response: RouterResponse, data:JSON?) {
		do {
			if let jsonResponse = data {
				try response.status(.OK).send(json:jsonResponse).end()
			} else {
				try response.status(.OK).end()
			}
		} catch {
			Log.error("Failed to send a response")
		}
	}

	init () {
		let idPath = "api/todos/:id"

		router.all("/*", middleware: BodyParser())
		router.all("/*", middleware: AllRemoteOriginMiddleware())
		router.options("/*") { (request, response, next) in
			response.headers["Access-Control-Allow-Headers"] = "accept, content-type"
			response.headers["Access-Control-Allow-Methods"] = "GET,HEAD,POST,DELETE,OPTIONS,PUT,PATCH"
			response.status(.OK)
			next()
		}

		router.get("/", handler: getAll)
		router.get(idPath, handler: getATodo)
		router.post("/", handler: createTodo)
		router.post(idPath, handler: updateATodo)
		router.put(idPath, handler: updateATodo)
		router.patch(idPath, handler: updateATodo)
		router.delete(idPath, handler: deleteATodo)
		router.delete("/", handler: deleteAll)
	}

	func getAll(request: RouterRequest, response: RouterResponse, next: () -> Void) {
		let todos = self.list.getAll()
		self.send(response, data: JSON(todos.jsonDictionary))
	}

	func getATodo(request: RouterRequest, response: RouterResponse, next: () -> Void) {
		guard let todoID = request.parameters["id"] else {
			Log.error("No id passed in")
			response.status(.badRequest)
			return
		}

		guard let todo = self.list.getTodo(with: todoID) else { return }
		self.send(response, data: JSON(todo.jsonDictionary))
	}

	func createTodo(request: RouterRequest, response: RouterResponse, next: () -> Void) {
		guard let json = self.collectJSONBody(request: request) else {
			Log.error("Invalid JSON")
			response.status(.badRequest)
			return
		}

		guard let title = json["title"].string else {
			Log.error("No title in JSON")
			response.status(.badRequest)
			return
		}

		let order = json["order"].int
		let completed = json["completed"].bool
		let item = self.list.add(with: title, order: order, completed: completed)
		self.send(response, data: JSON(item.jsonDictionary))
	}

	func updateATodo(request: RouterRequest, response: RouterResponse, next: () -> Void) {
		guard let json = self.collectJSONBody(request: request) else {
			Log.error("Invalid JSON")
			response.status(.badRequest)
			return
		}

		guard let id = request.parameters["id"] else {
			Log.error("No id")
			response.status(.badRequest)
			return
		}

		let title = json["title"].string
		let order = json["order"].int
		let completed = json["completed"].bool

		guard let todo = self.list.updateTodo(with: id, title: title, order: order, completed: completed) else {
			Log.error("Unable to update that todo")
			response.status(.internalServerError)
			return
		}

		self.send(response, data: JSON(todo.jsonDictionary))
	}

	func deleteATodo(request: RouterRequest, response: RouterResponse, next: () -> Void) {
		guard let id = request.parameters["id"] else {
			Log.error("No id")
			response.status(.badRequest)
			return
		}

		self.list.deleteTodo(with: id)
		self.send(response, data: nil)
	}

	func deleteAll(request: RouterRequest, response: RouterResponse, next: () -> Void) {
		self.list.deleteAll()
		self.send(response, data: nil)
	}
}