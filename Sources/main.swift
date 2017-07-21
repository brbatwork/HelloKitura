import Kitura
import HeliumLogger

HeliumLogger.use()

	let controller = TodoController()

Kitura.addHTTPServer(onPort: 8080, with: controller.router)
Kitura.run()
