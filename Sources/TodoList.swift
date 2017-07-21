import Foundation
import CloudFoundryConfig
import Configuration

struct TodoItem {
	let todoId : String
	let order : Int?
	let title : String
	let completed : Bool?
}

typealias JSONDictionary = [String:Any]

protocol JSONAble {
	var jsonDictionary : JSONDictionary { get }
}

extension TodoItem : JSONAble {
	var jsonDictionary : JSONDictionary {
		let manager = ConfigurationManager()
		manager.load(.environmentVariables)
		let url = manager.url + "/api/todos/" + self.todoId

		var dictionary = JSONDictionary()
		dictionary["id"] = self.todoId
		dictionary["order"] = self.order
		dictionary["completed"] = self.completed
		dictionary["title"] = self.title
		dictionary["url"] = url

		return dictionary
	}
}

extension Array where Element: JSONAble {
	var jsonDictionary : [JSONDictionary] {
		return self.map {$0.jsonDictionary}
	}
}

class TodoList {
	var list : [TodoItem] = [TodoItem]()
	var counter : Int = 0

	func getAll()-> [TodoItem] {
		return list
	}

	func getTodo(with id: String)->TodoItem? {
		let todo = list.filter {$0.todoId == id}.first
		return todo
	}

	func add(with title: String, order: Int?, completed: Bool?) -> TodoItem {
		let todoId = String(self.counter)
		let todo = TodoItem(todoId: todoId, order: order, title: title, completed: completed ?? false)
		list.append(todo)
		self.counter += 1
		return todo
	}

	func updateTodo(with id: String, title: String?, order: Int?, completed: Bool?) -> TodoItem? {
		guard let index = list.index(where: {(item) -> Bool in
				item.todoId == id
			}) else {
			return nil
		}

		let todo = TodoItem(todoId: id, order: order, title: title ?? self.list[index].title, completed: completed)
		self.list[index] = todo
		return todo
	}

	func deleteTodo(with id: String) {
		guard let index = list.index(where: {(item) -> Bool in
				item.todoId == id
		}) else {
			return
		}

		self.list.remove(at: index)
	}

	func deleteAll() {
		self.list = [TodoItem]()
	}
}