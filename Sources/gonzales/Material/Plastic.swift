final class Plastic: Material {

        init(kd: Texture<Spectrum>, ks: Texture<Spectrum>, roughness: Texture<FloatX>) {
                self.kd = kd
                self.ks = ks
                self.roughness = roughness
        }

        func computeScatteringFunctions(interaction: Interaction) -> (BSDF, BSSRDF?) {
                var bsdf = BSDF(interaction: interaction)
                let kd = self.kd.evaluate(at: interaction)
                if !kd.isBlack {
                        let diffuse = LambertianReflection(reflectance: kd)
                        bsdf.add(bxdf: diffuse)
                }
                let ks = self.ks.evaluate(at: interaction)
                if !ks.isBlack {
                        let dielectric = FresnelDielectric(etaI: 1.5, etaT: 1)
                        let roughness = self.roughness.evaluate(at: interaction)
                        let trowbridge = TrowbridgeReitzDistribution(alpha: (roughness, roughness))
                        let specular = MicrofacetReflection(reflectance: ks, distribution: trowbridge, fresnel: dielectric)
                        bsdf.add(bxdf: specular)
                }
		            return (bsdf, nil)
        }

        var kd: Texture<Spectrum>
        var ks: Texture<Spectrum>
        var roughness: Texture<FloatX>
}

func createPlastic(parameters: ParameterDictionary) throws -> Plastic {
        let kd = try parameters.findSpectrumTexture(name: "Kd", else: Spectrum(intensity: 0.25))
        let ks = try parameters.findSpectrumTexture(name: "Ks", else: Spectrum(intensity: 0.25))
        let roughness = try parameters.findFloatXTexture(name: "roughness", else: 0.1)
        return Plastic(kd: kd, ks: ks, roughness: roughness)
}

