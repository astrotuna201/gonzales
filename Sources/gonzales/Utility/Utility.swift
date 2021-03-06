import Foundation // log2, Process, URL, Pipe, Thread

// TODO: Read https://www.jessesquires.com/blog/floating-point-swift-ulp-and-epsilon/
// again and change this!!
let machineEpsilon = FloatX.ulpOfOne
let shadowEpsilon: FloatX = 0.00001
let oneMinusEpsilon: FloatX = 0.99999999999999989

var quick = false
var verbose = false
var singleRay = false
var singleRayCoordinate = Point2I()
var renderSynchronously = false
var justParse = false
var ptexMemory = 4 // GB
var sceneDirectory = String()

func radians(deg: FloatX) -> FloatX {
        return (FloatX.pi / 180) * deg
}

func gamma(n: Int) -> FloatX {
        return (FloatX(n) * machineEpsilon) / (1 - FloatX(n) * machineEpsilon)
}

func clamp<T: Comparable>(value: T, low: T, high: T) -> T {
        if value < low { return low }
        else if value > high { return high }
        else { return value }
}

func roundUpPower2(v: Int) -> Int {
        var v = v - 1
        v |= v >>  1
        v |= v >>  2
        v |= v >>  4
        v |= v >>  8
        v |= v >> 16 
        v |= v >> 32
        return v + 1
}

func log2Int(v: Int) -> UInt {
        return UInt(log2(FloatX(v)))
}

func gammaLinearToSrgb(value: FloatX) -> FloatX {
        if value <= 0.0031308 {
                return value / 12.92
        } else {
                return 1.055 * pow(value, 1.0 / 2.4) - 0.055
        }
}

func square(_ x: FloatX) -> FloatX { return x * x }

func gammaSrgbToLinear(value: FloatX) -> FloatX {
        if value <= 0.04045 {
                return value / 12.92
        } else {
                return pow((value + 0.055) / 1.055, 2.4)
        }
}

func lerp(with t: FloatX, between first: FloatX, and second: FloatX) -> FloatX {
        return (1 - t) * first + t * second
}

func lerp(with t: Spectrum, between first: Spectrum, and second: Spectrum) -> Spectrum {
        return (white - t) * first + t * second
}


@available(macOS 10.13, *)
func shell(_ launchPath: String, _ arguments: [String] = []) -> (String?, Int32) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: launchPath)
        task.arguments = arguments
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        do {
                try task.run()
        } catch {
                print("Error: \(error.localizedDescription)")
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()
        return (output, task.terminationStatus)
}

func demangle(symbol: String) -> String {
        if #available(macOS 10.13, *) {
                //let demangle = "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-demangle"
		//let demangle = "/home/gonsolo/downloads/swift-DEVELOPMENT-SNAPSHOT-2019-11-15-a-ubuntu18.04/usr/bin/swift-demangle"
		let demangle = "/home/gonsolo/bin/swift-demangle"
                let (output, _) = shell(demangle, ["-compact", symbol])
                return (output!).trimmingCharacters(in: .whitespacesAndNewlines)
	      } else {
		            return symbol
	      }
}

func printStack() {
        Thread.callStackSymbols.forEach {
                guard let dollar = $0.firstIndex(of: Character("$")) else { return }
                let start = $0.index(after: dollar)
                guard let plus = $0.firstIndex(of: Character("+")) else { return }
                let symbol = String($0[start..<plus])
                let demangled = demangle(symbol: symbol)
                print(demangled)
        }
}

// Just needed for Float 16.
// A cleaner way would be to let the former ones as is.
/*
public func sin(_ x: FloatX) -> FloatX {
        return FloatX(sin(Float(x)))
}

public func cos(_ x: FloatX) -> FloatX {
        return FloatX(cos(Float(x)))
}

public func log(_ x: FloatX) -> FloatX {
        return FloatX(log(Float(x)))
}

public func log2(_ x: FloatX) -> FloatX {
        return FloatX(log2(Float(x)))
}

public func pow(_ x: FloatX, _ y: FloatX) -> FloatX {
        return FloatX(pow(Float(x), Float(y)))
}

public func acos(_ x: FloatX) -> FloatX {
        return FloatX(acos(Float(x)))
}

public func atan2(_ x: FloatX, _ y: FloatX) -> FloatX {
        return FloatX(atan2(Float(x), Float(y)))
}

public func tan(_ x: FloatX) -> FloatX {
        return FloatX(tan(Float(x)))
}

public func exp(_ x: FloatX) -> FloatX {
        return FloatX(exp(Float(x)))
}
*/
