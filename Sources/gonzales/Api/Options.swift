struct Options {

        enum OptionError: Error {
                case camera, crop
        }

        var acceleratorParameters = ParameterDictionary()
        var cameraName  = "perspective"
        var cameraParameters = ParameterDictionary()
        var cameraToWorld = Transform()
        var filmName = "image"
        var filmParameters = ParameterDictionary()
        var integratorName = "path"
        var integratorParameters = ParameterDictionary()
        var samplerName = "random"
        var samplerParameters = ParameterDictionary()
        var filterName = "box"
        var filterParameters = ParameterDictionary()
        var lights = [Light]()
        var primitives = [Boundable & Intersectable]()
        var objects = ["": [Boundable & Intersectable]()]

        func makeFilm(filter: Filter) throws -> Film {
                var x = try filmParameters.findOneInt(called: "xresolution", else: 32)
                var y = try filmParameters.findOneInt(called: "yresolution", else: 32)
                if quick { x /= 4; y /= 4 }
                let resolution = Point2I(x: x, y: y)
                let fileName = try filmParameters.findString(called: "filename") ?? "gonzales.exr"
                let crop = try filmParameters.findFloatXs(called: "cropwindow")
                var cropWindow = Bounds2f()
                if !crop.isEmpty {
                        guard crop.count == 4 else { throw OptionError.crop }
                        cropWindow.pMin = Point2F(x: crop[0], y: crop[2])
                        cropWindow.pMax = Point2F(x: crop[1], y: crop[3])
                }
                return Film(name: fileName, resolution: resolution, fileName: fileName, filter: filter, crop: cropWindow)
        }

        func makeFilter(name: String, parameters: ParameterDictionary) throws -> Filter {

                func makeSupport(withDefault support: (FloatX, FloatX) = (2, 2)) throws -> Vector2F {
                        let xwidth = try parameters.findOneFloatX(called: "xwidth", else: support.0)
                        let ywidth = try parameters.findOneFloatX(called: "ywidth", else: support.1)
                        return Vector2F(x: xwidth, y: ywidth)
                }

                var filter: Filter
                switch name {
                case "triangle":
			                  let support = try makeSupport()
                        filter = TriangleFilter(support: support)
                case "box":
                        let support = try makeSupport(withDefault: (0.5, 0.5))
                        filter = BoxFilter(support: support)
                case "gaussian":
                        let support = try makeSupport()
                        let alpha = try parameters.findOneFloatX(called: "alpha", else: 2)
                        filter = GaussianFilter(withSupport: support, withAlpha: alpha)
                default:
                        fatalError("Unknown pixel filter!")
                }
                return filter
        }

        func makeCamera() throws -> Camera {
                guard cameraName == "perspective" else { throw OptionError.camera }
                let filter = try makeFilter(name: filterName, parameters: filterParameters)
                let film = try makeFilm(filter: filter)
                let frame = FloatX(film.image.fullResolution.x) / FloatX(film.image.fullResolution.y)
                var screen = Bounds2f()

                if frame > 1 {
		        // Blender does not like this
                        screen.pMin.x = -frame
                        screen.pMax.x =  frame
                        screen.pMin.y = -1
                        screen.pMax.y =  1
                } else {
                        screen.pMin.x = -1
                        screen.pMax.x =  1
                        screen.pMin.y = -1 / frame
                        screen.pMax.y =  1 / frame
                }
                let screenWindow = try cameraParameters.findFloatXs(called: "screenwindow")
                if !screenWindow.isEmpty {
                        if screenWindow.count != 4 {
                                warning("screenwindow must be four coordinates!")
                        } else {
                                screen.pMin.x = screenWindow[0]
                                screen.pMax.x = screenWindow[1]
                                screen.pMin.y = screenWindow[2]
                                screen.pMax.y = screenWindow[3]
                        }
                }
                let fov = try cameraParameters.findOneFloatX(called: "fov", else: 30)
                let focalDistance = try cameraParameters.findOneFloatX(called: "focaldistance", else: 1e6)
                let lensRadius = try cameraParameters.findOneFloatX(called: "lensradius", else: 0)
                return try PerspectiveCamera(cameraToWorld: cameraToWorld, screenWindow: screen, fov: fov,
                                             focalDistance: focalDistance, lensRadius: lensRadius, film: film)
        }

        func makeIntegrator(sampler: Sampler) throws -> Integrator {
                if options.integratorName != "path" {
                        warning("Integrator \(options.integratorName) not implemented, using path integrator!")
                }
                let maxDepth = try options.integratorParameters.findOneInt(called: "maxdepth", else: 1)
                return PathIntegrator(maxDepth: maxDepth)
        }

        func makeSampler(film: Film) throws -> Sampler {
                if samplerName != "random" {
                        warning("Unknown sampler, using random sampler.")
                }
                let sampler = try createRandomSampler(parameters: samplerParameters)
                if quick {
                        sampler.samplesPerPixel = 1
                }
                return sampler
        }

        func makeRenderer(scene: Scene) throws -> Renderer {
                let camera = try makeCamera()
                let sampler = try makeSampler(film: camera.film)
                let integrator = try makeIntegrator(sampler: sampler)
                return Renderer(camera: camera, integrator: integrator, sampler: sampler, scene: scene)
        }

        mutating func makeScene() -> Scene {
                let accelerator = makeAccelerator(primitives: &primitives)
                primitives = []
                objects = [:]
                let scene = Scene(aggregate: accelerator, lights: lights)
                return scene
        }
}

