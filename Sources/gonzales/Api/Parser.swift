import Foundation // Scanner, CharacterSet

enum RenderStatement : String {
        case accelerator        = "Accelerator"
        case areaLightSource    = "AreaLightSource"
        case attributeBegin     = "AttributeBegin"
        case attributeEnd       = "AttributeEnd"
        case camera             = "Camera"
        case concatTransform    = "ConcatTransform"
        case film               = "Film"
        case include            = "Include"
        case integrator         = "Integrator"
        case lightSource        = "LightSource"
        case lookAt             = "LookAt"
        case makeNamedMaterial  = "MakeNamedMaterial"
        case material           = "Material"
        case namedMaterial      = "NamedMaterial"
        case objectBegin        = "ObjectBegin"
        case objectEnd          = "ObjectEnd"
        case objectInstance     = "ObjectInstance"
        case pixelFilter        = "PixelFilter"
        case reverseOrientation = "ReverseOrientation"
        case rotate             = "Rotate"
        case sampler            = "Sampler"
        case scale              = "Scale"
        case shape              = "Shape"
        case texture            = "Texture"
        case transform          = "Transform"
        case transformBegin     = "TransformBegin"
        case transformEnd       = "TransformEnd"
        case translate          = "Translate"
        case worldBegin         = "WorldBegin"
        case worldEnd           = "WorldEnd"
}

func ascii(_ x: UInt8) -> String {
        return ascii(Int32(x))
}

func ascii(_ x: Int32) -> String {
        switch x {
        case EOF: return "EOF"

        case   0: return "EOF"
        case   9: return "\t"
        case  10: return "\n"
        case  13: return "\r"

        case  32: return " "
        case  33: return "!"
        case  34: return "\""
        case  35: return "#"
        case  36: return "$"
        case  37: return "%"
        case  38: return "&"
        case  39: return "'"
        case  40: return "("
        case  41: return ")"
        case  42: return "*"
        case  43: return "+"
        case  44: return ","
        case  45: return "-"
        case  46: return "."
        case  47: return "/"
        case  48: return "0"
        case  49: return "1"
        case  50: return "2"
        case  51: return "3"
        case  52: return "4"
        case  53: return "5"
        case  54: return "6"
        case  55: return "7"
        case  56: return "8"
        case  57: return "9"
        case  58: return ":"
        case  59: return ";"
        case  60: return "<"
        case  61: return "="
        case  62: return ">"
        case  63: return "?"
        case  64: return "@"

        case  65: return "A"
        case  66: return "B"
        case  67: return "C"
        case  68: return "D"
        case  69: return "E"
        case  70: return "F"
        case  71: return "G"
        case  72: return "H"
        case  73: return "I"
        case  74: return "J"
        case  75: return "K"
        case  76: return "L"
        case  77: return "M"
        case  78: return "N"
        case  79: return "O"
        case  80: return "P"
        case  81: return "Q"
        case  82: return "R"
        case  83: return "S"
        case  84: return "T"
        case  85: return "U"
        case  86: return "V"
        case  87: return "W"
        case  88: return "X"
        case  89: return "Y"
        case  90: return "Z"
        case  91: return "["
        case  92: return "\\"
        case  93: return "]"
        case  95: return "_"
        case  96: return "`"
        case  97: return "a"
        case  98: return "b"
        case  99: return "c"
        case 100: return "d"
        case 101: return "e"
        case 102: return "f"
        case 103: return "g"
        case 104: return "h"
        case 105: return "i"
        case 106: return "j"
        case 107: return "k"
        case 108: return "l"
        case 109: return "m"
        case 110: return "n"
        case 111: return "o"
        case 112: return "p"
        case 113: return "q"
        case 114: return "r"
        case 115: return "s"
        case 116: return "t"
        case 117: return "u"
        case 118: return "v"
        case 119: return "w"
        case 120: return "x"
        case 121: return "y"
        case 122: return "z"
        case 123: return "{"
        case 124: return "|"
        case 125: return "}"
        case 126: return "~"

        default:
                print(#function, "Unknown: ", x)
                exit(0)
        }
}

func rawScanGlobal(file: UnsafeMutablePointer<FILE>) -> Int32? {
        return fgetc(file)
}

func rawPeekGlobal(file: UnsafeMutablePointer<FILE>) -> Int32? {
        let c = fgetc(file)
        ungetc(c, file)
        return c
}

func match(character: String, in list: [String]) -> Bool {
        for l in list {
                if character == l { return true }
        }
        return false
}

let eof:                UInt8 =   0
let htab:               UInt8 =   9
let newline:            UInt8 =  10
let space:              UInt8 =  32
let quote:              UInt8 =  34
let hashmark:           UInt8 =  35
let minus:              UInt8 =  45
let dot:                UInt8 =  46
let bracketOpen:        UInt8 =  91
let bracketClose:       UInt8 =  93
let e:                  UInt8 = 101

enum PbrtScannerError: Error {
        case noFile
        case unsupported
}

final class PbrtScanner {

        init(path: String) throws {
                guard let s = InputStream(fileAtPath: path) else {
                        throw PbrtScannerError.noFile
                }
                stream = s
                stream.open()
                if stream.streamStatus == .error {
                        throw PbrtScannerError.noFile
                }
                var bytes = Array<UInt8>(repeating: 0, count: bufferLength)
                buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferLength)
                buffer.initialize(from: &bytes, count: bufferLength)
                bufferIndex = 0
                bytesRead = stream.read(buffer, maxLength: bufferLength)
                c = 0
        }

        deinit {
                buffer.deallocate()
        }

        func peekOne() {
                if bytesRead == 0 {
                        return
                }
                c = buffer[bufferIndex]
        }

        func scanOne() {
                if bytesRead == 0 {
                        c = eof
                        return
                }
                c = buffer[bufferIndex]
                bufferIndex += 1
                scanLocation += 1
                if bufferIndex == bytesRead {
                        bufferIndex = 0
                        bytesRead = stream.read(buffer, maxLength: bufferLength)
                }
        }

        func peekString(_ expected: String) -> String? {
                skipWhitespace()
                peekOne()
                let s = ascii(c)
                if s != expected {
                        return nil
                } else {
                        return s
                }
        }

        func scanString(_ expected: String) -> String? {
                skipWhitespace()
                peekOne()
                let s = ascii(c)
                if s != expected {
                        return nil
                } else {
                        scanOne()
                        return s
                }
        }

        func scanUpToString(_ input: String) -> String? {
                let s = scanUpToCharactersList(from: [input])
                return s

        }

        func isInteger(_ c: UInt8) -> Bool {
                if c >= 48 && c <= 57   { return true }
                else                    { return false }
        }

        func scanInt(_ i: inout Int) -> Bool {

                skipWhitespace()
                peekOne()
                var isNegative = false
                if c == minus {
                        isNegative = true
                        scanOne()
                }
                peekOne()
                if !isInteger(c) {
                        return false
                }
                i = 0
                while isInteger(c) {
                        scanOne()
                        i = 10 * i + (Int(c) - 48)
                        peekOne()
                }
                if isNegative {
                        i = -i
                }
                return true
        }

        func scanFloat(_ float: inout Float) throws -> Bool {
                var i = 0

                // scanInt scans -0 as 0 so we have to remember whether we are negative
                skipWhitespace()
                peekOne()
                var isNegative = false
                if c == minus {
                        isNegative = true
                }

                if !scanInt(&i) { return false }
                var f = Double(i)
                peekOne()
                if c == dot {
                        scanOne()
                        var tenth = 0.1
                        peekOne()
                        while isInteger(c) {
                                scanOne()
                                if f < 0 {
                                        f -= tenth * Double(c - 48)
                                } else {
                                        f += tenth * Double(c - 48)
                                }
                                tenth *= 0.1
                                peekOne()
                        }
                }
                peekOne()
                var exponent = 0
                if c == e {
                        scanOne()
                        if !scanInt(&exponent) {
                                exponent = 0
                        }
                        f = f * pow(Double(10), Double(exponent))
                }

                float = FloatX(f)

                if isNegative && i == 0 {
                        float = -float
                }
                return true
        }

        func isWhitespace(_ c: UInt8) -> Bool {
                switch c {
                case  9:        return true // htab
                case 10:        return true // new line
                case 32:        return true // space
                default:        return false
                }
        }

        func skipWhitespace() {
                while true {
                        peekOne()
                        if !isWhitespace(c) {
                                return
                        }
                        scanOne()
                }
        }

        func scanUpToCharactersList(from list: [String]) -> String? {
                var string = String()
                skipWhitespace()
                while true {
                        peekOne()
                        if c == eof {
                                isAtEnd = true
                                return nil
                        }
                        let s = ascii(c)
                        if match(character: s, in: list) {
                                break
                        }
                        string.append(s)
                        scanOne()
                }
                return string
        }

        var scanLocation = 0
        var isAtEnd = false
        var bytesRead: Int
        var buffer: UnsafeMutablePointer<UInt8>
        let bufferLength = 64 * 1024
        var bufferIndex: Int
        var stream: InputStream
        var c: UInt8
}

@available(OSX 10.15, *)
final class Parser {

        var scanner: PbrtScanner
        let fileName: String

        init(fileName: String, function: String = #function) throws {
                self.scanner = try PbrtScanner(path: fileName)
                self.fileName = fileName
        }

        func bail(function: String = #function, file: String = #file, line: Int = #line, message: String = "") throws -> Never {
                throw RenderError.parser(function: function, file: file, line: line, message: message)
        }

        func parseString() throws -> String {
                var string = ""
                var ok = true
                ok = try parseString(string: &string)
                if ok {
                        return string
                } else {
                        try bail()
                }
        }

        func parseTextures() throws -> [String] {
                var textures = [String]()
                var string = ""
                var ok = true
                ok = try parseString(string: &string)
                if ok {
                        textures.append(string)
                }
                return textures
        }

        func parseBool() throws -> [Bool] {
                var value = ""
                guard try parseString(string: &value) else {
                  try bail()
                }
                switch value {
                case "true": return [true]
                case "false": return [false]
                default: try bail()
                }
        }

        func parseString(string: inout String) throws -> Bool {
		            guard scanner.scanString("\"") != nil else { 
                        return false
                }
                guard let s = scanner.scanUpToString("\"") else {
                        try bail()
                }
                string = s
                guard scanner.scanString("\"") != nil else {
                        try bail()
                }
                return true
        }

        func parseFloatXs() throws -> [FloatX] {
                var values = [FloatX]()
                while let value = try parseFloatX() {
                        values.append(value)
		            }
                return values
        }

        func parseInteger() -> [Int] {
                var integers = [Int]()
                var i = Int()
                var ok = true
                while ok {
                        ok = scanner.scanInt(&i)
                        if ok {
                                integers.append(i)
                        }
                }
                return integers 
        }

        func parseFloatX() throws -> FloatX? {
                var x: Float = 0
                guard try scanner.scanFloat(&x) else { return nil }
                return FloatX(x)
        }

        func parseThreeFloatXs() throws -> (FloatX, FloatX, FloatX)? {
                guard let x = try parseFloatX() else { return nil }
                guard let y = try parseFloatX() else { return nil }
                guard let z = try parseFloatX() else { return nil }
                let f = (x, y, z)
                return f
        }

        func parseSpectrum() throws -> [Spectrum] {
                var spectra = [Spectrum]()
                while let f = try parseThreeFloatXs() {
                        let spectrum = Spectrum(rgb: f)
                        spectra.append(spectrum)
                }
                return spectra
        }

        func parsePoint() throws -> Point {
                guard let f = try parseThreeFloatXs() else { try bail() }
                return Point(xyz: f)
        }

        func parsePoints() throws -> [Point] {
                var points = [Point]()
                while let f = try parseThreeFloatXs() {
                        let point = Point(xyz: f)
                        points.append(point)
                }
                return points
        }

        func parseVector() throws -> Vector {
                guard let f = try parseThreeFloatXs() else { try bail() }
                return Vector(xyz: f)
        }


        func parseVectors() throws -> [Vector] {
                var vectors = [Vector]()
                while let f = try parseThreeFloatXs() {
                        let vector = Vector(xyz: f)
                        vectors.append(vector)
                }
                return vectors
        }

        func parseNormals() throws -> [Normal] {
                var normals = [Normal]()
                while let f = try parseThreeFloatXs() {
                        let normal = Normal(xyz: f)
                        normals.append(normal)
                }
                return normals
        }

        func parseParameter() throws -> (String,Parameter)? {
                guard let _ = scanner.scanString("\"") else { return nil }
                guard let type = scanner.scanUpToCharactersList(from: ["\n", " "]) else {
			                  try bail()
		            }
                //guard Parameter.isType(type) else {
                //        try bail(message: "Unknown type: |\(type)|")
                //}
                guard let name = scanner.scanUpToCharactersList(from: ["\""]) else {
                        try bail()
                }
                var parameter: Parameter
                guard let _ = scanner.scanString("\"") else {
                        try bail()
                }
                _ = scanner.scanString("[") // optional
                switch type {
                case "bool":
                        let bools = try parseBool()
                        parameter = bools
                case "float":
                        let doubles = try parseFloatXs()
                        parameter = doubles
                case "integer":
                        let ints = parseInteger()
                        parameter = ints
                case "normal":
                        let normals = try parseNormals()
                        parameter = normals
                case "point", "point3":
                        let points = try parsePoints()
                        parameter = points
                case "point2":
                        let doubles = try parseFloatXs()
                        parameter = doubles
                        // TODO: Parse as Point2f
                case "rgb", "color":
                        let rgbs = try parseSpectrum()
                        parameter = rgbs
                case "string":
                        // TODO: Only one string supported
                        let string = try parseString()
                        let strings = [string]
                        parameter = strings
                case "texture":
                        let textures = try parseTextures()
                        parameter = textures
                default:
                        try bail()
                }
                _ = scanner.scanString("]") // optional
                return (name, parameter)
        }

        func parseParameters() throws -> ParameterDictionary {
                var parameters = ParameterDictionary()
                var nameAndParameter = try parseParameter()
                while nameAndParameter != nil {
                        //parameters.append(parameter!)
                        let name = nameAndParameter!.0
                        let parameter = nameAndParameter!.1

                        //if name == "Kd" {
                        //        print("set \(name) to \(type(of: parameter))")
                        //}

                        parameters[name] = parameter
                        parseComments() // TODO: This does not belong here!
                        nameAndParameter = try parseParameter()
                }
                return parameters
        }

        func parseIntegrator() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                try api.integrator(name: name, parameters: parameters)
       }

        func parseLightSource() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                try api.lightSource(name: name, parameters: parameters)
        }

        func parseLookAt() throws {
                let eye = try parsePoint()
                let at = try parsePoint()
                let up = try parseVector()
                try api.lookAt(eye: eye, at: at, up: up)
        }

        func parseRotate() throws {
                guard let angle = try parseFloatX() else { try bail() }
                guard let f = try parseThreeFloatXs() else { try bail() }
                let axis = Vector(xyz: f)
                try api.rotate(by: FloatX(angle), around: axis)
        }

        func scanTransform() throws -> [FloatX] {
                guard let _ = scanner.scanString("[") else { try bail() }
                var values = [FloatX]()
                for _ in 0..<16 {
                        guard let value = try parseFloatX() else { try bail() }
                        values.append(value)
                }
                guard let _ = scanner.scanString("]") else { try bail() }
                return values
        }

        func parseTransform() throws {
                let values = try scanTransform()
                try api.transform(values: values)
        }

        func parseTransformBegin() throws {
                try api.transformBegin()
        }

        func parseTransformEnd() throws {
                try api.transformEnd()
        }

        func parseTranslate() throws {
                guard let f = try parseThreeFloatXs() else { try bail() }
                let translation = Vector(xyz: f)
                try api.translate(by: translation)
        }

        func parseSampler() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                api.sampler(name: name, parameters: parameters)
        }

        func parseScale() throws {
                guard let f = try parseThreeFloatXs() else { try bail() }
                try api.scale(x: f.0, y: f.1, z: f.2)
        }

        func parsePixelFilter() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                api.pixelFilter(name: name, parameters: parameters)
        }

        func parseReverseOrientation() {
                warning("Ignoring reverseOrientation!")
        }

        func parseFilm() throws {
                let name = try parseString()
                guard name == "image" else {
                        try bail()
                }
                let parameters = try parseParameters()
                try api.film(name: name, parameters: parameters)
        }

        func parseInclude() throws {
                let name = try parseString()
                try api.include(file: name)
        }

        func parseCamera() throws {
                let name = try parseString()
                guard name == "perspective" else {
                        try bail()
                }
                let parameters = try parseParameters()
                try api.camera(name: name, parameters: parameters)
        }

        func parseConcatTransform() throws {
                let values = try scanTransform()
                try api.concatTransform(values: values)
        }

        func parseWorldBegin() throws {
                api.worldBegin()
        }

        func parseWorldEnd() throws {
                try api.worldEnd()
        }

        func parseMakeNamedMaterial() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                try api.makeNamedMaterial(name: name, parameters: parameters)
        }

        func parseMaterial() throws {
                let type = try parseString()
                let parameters = try parseParameters()
                try api.material(type: type, parameters: parameters)
        }

        func parseNamedMaterial() throws {
                let name = try parseString()
                try api.namedMaterial(name: name)
        }

        func parseObjectBegin() throws {
                let name = try parseString()
                try api.objectBegin(name: name)
        }

        func parseObjectEnd() throws {
                try api.objectEnd()
        }

        func parseObjectInstance() throws {
                let name = try parseString()
                try api.objectInstance(name: name) 
        }

        func parseShape() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                try api.shape(name: name, parameters: parameters)
        }

        func parseTexture() throws {
                let textureName = try parseString()
                let textureType = try parseString()
                let textureClass = try parseString()
                let parameters = try parseParameters()
                try api.texture(name: textureName, type: textureType, textureClass: textureClass, parameters: parameters)
        }

        func parseAttributeBegin() throws {
                try api.attributeBegin()
        }

        func parseAttributeEnd() throws {
                try api.attributeEnd()
        }

        func parseAccelerator() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                try api.accelerator(name: name, parameters: parameters)
        }

        func parseAreaLightSource() throws {
                let name = try parseString()
                let parameters = try parseParameters()
                try api.areaLight(name: name, parameters: parameters)
        }

        func parseComment() -> Bool {
                let hashmark = scanner.peekString("#")
                if hashmark != nil {
                        _ = scanner.scanUpToCharactersList(from: ["\n"])
                        return true
                }
                return false
        }

        func parseComments() {
                var commentFound: Bool
                repeat {
                        commentFound = parseComment()
                } while commentFound
        }

        func handleRenderStatement(_ input: String) throws {
                guard let statement = RenderStatement(rawValue: input) else {
                        try bail(message: "Unknown RenderStatement: |\(input)| in file \(fileName) at \(scanner.scanLocation)")
                }
                switch statement {
                case .accelerator:              try parseAccelerator()
                case .areaLightSource:          try parseAreaLightSource()
                case .attributeBegin:           try parseAttributeBegin()
                case .attributeEnd:             try parseAttributeEnd()
                case .camera:                   try parseCamera()
                case .concatTransform:          try parseConcatTransform()
                case .film:                     try parseFilm()
                case .include:                  try parseInclude()
                case .integrator:               try parseIntegrator()
                case .lightSource:              try parseLightSource()
                case .lookAt:                   try parseLookAt()
                case .makeNamedMaterial:        try parseMakeNamedMaterial()
                case .material:                 try parseMaterial()
                case .namedMaterial:            try parseNamedMaterial()
                case .objectBegin:              try parseObjectBegin()
                case .objectEnd:                try parseObjectEnd()
                case .objectInstance:           try parseObjectInstance()
                case .pixelFilter:              try parsePixelFilter()
                case .reverseOrientation:       parseReverseOrientation()
                case .rotate:                   try parseRotate()
                case .sampler:                  try parseSampler()
                case .scale:                    try parseScale()
                case .shape:                    try parseShape()
                case .texture:                  try parseTexture()
                case .transform:                try parseTransform()
                case .transformBegin:           try parseTransformBegin()
                case .transformEnd:             try parseTransformEnd()
                case .translate:                try parseTranslate()
                case .worldBegin:               try parseWorldBegin()
                case .worldEnd:                 try parseWorldEnd()
                }
        }

        func parse() throws {
                while !scanner.isAtEnd {
                        parseComments()
                        if scanner.isAtEnd { return }
                        guard let buffer = scanner.scanUpToCharactersList(from: ["\n", " "]) else {
                                if scanner.isAtEnd { return }
                                try bail(message: "Parser error in file \(fileName) at \(scanner.scanLocation)")
			                  }
                        try handleRenderStatement(buffer)
                }
        }
}

