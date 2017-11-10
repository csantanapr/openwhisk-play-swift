// Imports
import Foundation
import KituraContracts


let env = ProcessInfo.processInfo.environment
let inputStr: String = env["WHISK_INPUT"] ?? """
{"id":42,"name":"Carlos"}
"""
let json = inputStr.data(using: .utf8, allowLossyConversion: true)!

print("Here is WHISK_INPUT \(inputStr)")
/*
// Simulate JSON payload (conforms to Employee struct below)
let json = """
{
 "name": "John Doe",
 "id": 123456
}
""".data(using: .utf8)! // our data in native (JSON) format
*/

// Domain model/entity
struct Employee: Codable {
  let id: Int
  let name: String
}

// traditional main function
func main_traditional(input: [String:Any]) -> [String:Any] {
    return input
}

// codable main function (async)
func main_codable_async(input: Employee, respondWith: (Employee?, RequestError?) -> Void) -> Void {
    // For simplicity, just passing same Employee instance forward
    respondWith(input, nil)
}

// codable main function (async)
func main_codable_async_vanilla(input: Employee, respondWith: (Employee?, Error?) -> Void) -> Void {
    // For simplicity, just passing same Employee instance forward
    respondWith(input, nil)
}


// codable main function (sync)
func main_codable_sync(input: Employee) -> Employee {
    // For simplicity, just returning back the same Employee instance
    return input
}



// snippet of code "injected" (wrapper code for invoking traditional main)
func _run_main(mainFunction: ([String: Any]) -> [String: Any]) -> Void {
    print("------------------------------------------------")
    print("Using traditional style for invoking action...([String: Any]) -> [String: Any]")
    let parsed = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
    let result = mainFunction(parsed)
    if JSONSerialization.isValidJSONObject(result) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: result, options: [])
            if let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8) {
                print("\(jsonStr)")
            } else {
                print("Error serializing data to JSON, data conversion returns nil string")
            }
        } catch {
            print(("\(error)"))
        }
    } else {
        print("Error serializing JSON, data does not appear to be valid JSON")
    }
}

// snippet of code "injected" (wrapper code for invoking codable main)
func _run_main<In: Codable, Out: Codable>(mainFunction: CodableClosure<In, Out>) {
    print("------------------------------------------------")
    print("Using codable style for invoking action (async style)...")
    
    guard let input = try? JSONDecoder().decode(In.self, from: json) else {
        print("Something went really wrong...")
        return
    }
    
    let resultHandler: CodableResultClosure<Out> = { out, error in
        if let out = out {
            let jsonEncoder = JSONEncoder()
            do {
                let jsonData = try jsonEncoder.encode(out)
                let jsonString = String(data: jsonData, encoding: .utf8)
                print("\(jsonString!)")
            }
            catch {
            }
        }
    }
    
    let _ = mainFunction(input, resultHandler)
}

// snippet of code "injected" (wrapper code for invoking codable main - async - vanilla)
func _run_main<In: Codable, Out: Codable>(mainFunction: (In, (Out?, Error?) -> Void) -> Void) {
    print("------------------------------------------------")
    print("Using codable style for invoking action (async style - vanilla)...")
    
    guard let input = try? JSONDecoder().decode(In.self, from: json) else {
        print("Something went really wrong...")
        return
    }
    
    let resultHandler = { (out: Out?, error: Error?) in
        if let out = out {
            let jsonEncoder = JSONEncoder()
            do {
                let jsonData = try jsonEncoder.encode(out)
                let jsonString = String(data: jsonData, encoding: .utf8)
                print("\(jsonString!)")
            }
            catch {
            }
        }
    }
    
    let _ = mainFunction(input, resultHandler)
}


// snippet of code "injected" (wrapper code for invoking codable main - sync - vanilla)
func _run_main<In: Codable, Out: Codable>(mainFunction: (In) -> Out) -> Void {
    print("------------------------------------------------")
    print("Using codable style for invoking action (sync style - vanilla)...")
    
    guard let input = try? JSONDecoder().decode(In.self, from: json) else {
        print("Something went really wrong...")
        return
    }
    
    let out = mainFunction(input)
    let jsonEncoder = JSONEncoder()
    do {
        let jsonData = try jsonEncoder.encode(out)
        let jsonString = String(data: jsonData, encoding: .utf8)
        print("\(jsonString!)")
    }
    catch {
    }
}

// snippets of code "injected", dependending on the type of function the developer
// wants to use traditional vs codable
_run_main(mainFunction:main_traditional)
_run_main(mainFunction:main_codable_async)
_run_main(mainFunction:main_codable_async_vanilla)
_run_main(mainFunction:main_codable_sync)



