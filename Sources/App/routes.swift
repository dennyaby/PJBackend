import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    router.get("api", "discount_codes") { request -> [Code] in
        return CodesManager.instance.getCodes()
    }
    // Basic "It works" example
    router.get { req in
        return "It works!"
    }
    
    router.get("hello") { req in
        return "Hello, world!"
    }

}
