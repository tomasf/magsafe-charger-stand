import SwiftSCAD

struct Charger {
    let name: String
    let diameter: Double
    let thickness: Double
    let cableDiameter: Double
    let strainReliefDiameter: Double
} 

let allChargers = [
    Charger(name: "57mm", diameter: 57.5, thickness: 5.5, cableDiameter: 3.1, strainReliefDiameter: 4.2),
    Charger(name: "56mm", diameter: 55.95, thickness: 5.6, cableDiameter: 3.2, strainReliefDiameter: 4.2)
]

save(environment: .defaultEnvironment.withTolerance(0.3)) {
    for charger in allChargers {
        let top = Top(charger: charger)
        top
            .named("magsafe-stand-top-\(charger.name)")

        for useWeightNuts in [false, true] {
            let suffix = useWeightNuts ? "-weighted" : ""
            let base = Base(charger: charger, useWeightNuts: useWeightNuts)

            base
                .forceRendered()
                .named("magsafe-stand-base\(suffix)-\(charger.name)")

            base
                .attaching {
                    top
                        .rotated(y: 180°)
                        .translated(x: top.mountOffset, z: top.thickness)
                }
                .forceRendered()
                .named("magsafe-stand-assembled\(suffix)-\(charger.name)")
        }
    }
}
