// Imports
import Foundation
import KituraContracts
/*
 
import Foundation

#if os(Linux)
    import Glibc
#endif

func _whisk_json2dict(txt: String) -> [String:Any]? {
    if let data = txt.data(using: String.Encoding.utf8, allowLossyConversion: true) {
        do {
            return WhiskJsonUtils.jsonDataToDictionary(jsonData: data)
        } catch {
            return nil
        }
    }
    return nil
}


func _run_main(mainFunction: ([String: Any]) -> [String: Any]) -> Void {
    let env = ProcessInfo.processInfo.environment
    let inputStr: String = env["WHISK_INPUT"] ?? "{}"
    
    if let parsed = _whisk_json2dict(txt: inputStr) {
        let result = mainFunction(parsed)
        
        if result is [String:Any] {
            do {
                if let respString = WhiskJsonUtils.dictionaryToJsonString(jsonDict: result) {
                    print("\(respString)")
                } else {
                    print("Error converting \(result) to JSON string")
                    #if os(Linux)
                        fputs("Error converting \(result) to JSON string", stderr)
                    #endif
                }
            } catch {
                print("Error serializing response \(error)")
                #if os(Linux)
                    fputs("Error serializing response \(error)", stderr)
                #endif
            }
        } else {
            print("Cannot serialize response: \(result)")
            #if os(Linux)
                fputs("Cannot serialize response: \(result)", stderr)
            #endif
        }
    } else {
        print("Error: couldn't parse JSON input.")
        #if os(Linux)
            fputs("Error: couldn't parse JSON input.", stderr)
        #endif
    }
}
*/

// use SwiftyJSON to serialize JSON object because of bug in Linux Swift 3.0
// https://github.com/IBM-Swift/SwiftRuntime/issues/230
func dictionaryToJsonString(jsonDict: [String:Any]) -> String? {
    if JSONSerialization.isValidJSONObject(jsonDict) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: [])
            if let jsonStr = String(data: jsonData, encoding: String.Encoding.utf8) {
                return jsonStr
            } else {
                print("Error serializing data to JSON, data conversion returns nil string")
            }
        } catch {
            print(("\(error)"))
        }
    } else {
        print("Error serializing JSON, data does not appear to be valid JSON")
    }
    return nil
}

let env = ProcessInfo.processInfo.environment
let inputStr: String = env["WHISK_INPUT"] ?? "{}"
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
func main_traditional(args: [String:Any]) -> [String:Any] {
    return args
}

// codable main function with async
func main_codable(input: Employee, respondWith: (Employee?, RequestError?) -> Void) -> Void {
    // For simplicity, just passing same Employee instance forward
    respondWith(input, nil)
}



// snippet of code "injected" (wrapper code for invoking traditional main)

func _run_main(mainFunction: ([String: Any]) -> [String: Any]) -> Void {
    print("------------------------------------------------")
    print("Using traditional style for invoking action...")
    let parsed = try! JSONSerialization.jsonObject(with: json, options: []) as! [String: Any]
    let result = mainFunction(parsed)
    if result is [String:Any] {
        do {
            if let respString = dictionaryToJsonString(jsonDict: result) {
                print("\(respString)")
            } else {
                print("Error converting \(result) to JSON string")
                #if os(Linux)
                    fputs("Error converting \(result) to JSON string", stderr)
                #endif
            }
        } catch {
            print("Error serializing response \(error)")
            #if os(Linux)
                fputs("Error serializing response \(error)", stderr)
            #endif
        }
    } else {
        print("Cannot serialize response: \(result)")
        #if os(Linux)
            fputs("Cannot serialize response: \(result)", stderr)
        #endif
    }
}

// snippet of code "injected" (wrapper code for invoking codable main)
func _run_main<In: Codable, Out: Codable>(mainFunction: CodableClosure<In, Out>) {
    print("------------------------------------------------")
    print("Using codable style for invoking action...")
    
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

// codable main function with output sync
func main_codable_simple(input: Codable) -> Codable {
    // return codable
    return input
}
// snippet of code "injected" (wrapper code for invoking codable main)
func _run_main<In: Codable, Out: Codable>(mainFunction: (In) -> Out) -> Void {
    print("------------------------------------------------")
    print("Using codable style for invoking action...")
    
    guard let input = try? JSONDecoder().decode(In.self, from: json) else {
        print("Something went really wrong...")
        return
    }
    let result = mainFunction(input)
    print("\(result)")
}
//_run_main(mainFunction:main_codable_simple)
// snippets of code "injected", dependending on the type of function the developer 
// wants to use traditional vs codable
_run_main(mainFunction:main_traditional)
_run_main(mainFunction:main_codable)



