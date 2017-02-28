//  Copyright © 2016 Scott Talbot. All rights reserved.

import Foundation


func usage() -> Never {
    fputs("Usage: STEventSourceClient <url>\n", stderr)
    exit(1)
}


func processNameAndArguments(_ processInfo: ProcessInfo) -> (String, [String]) {
    let arguments = processInfo.arguments
    guard let processName = arguments.first else {
        return ("", [])
    }
    return (processName, Array(arguments[1..<arguments.count]))
}


let (processName, arguments) = processNameAndArguments(ProcessInfo.processInfo)

guard arguments.count == 1 else {
    usage()
}

guard let urlString = arguments.last, let url = URL(string: urlString) else {
    usage()
}


let e = STEventSource(url: url, handler: { event in
    print("\(event)")
}) { error in
    if let error = error {
        print("error: \(error.localizedDescription)")
        exit(1)
    }
    exit(0)
}

do {
    try e.open()
} catch {
    print("error: \(error.localizedDescription)")
    exit(1)
}


RunLoop.main.run()
