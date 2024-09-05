import Foundation
import SwiftSCAD

struct Top: Shape3D {
    let charger: Charger

    let frontThickness = 0.4
    var thickness: Double { frontThickness + charger.thickness }

    // Lip for snapping into place
    let lipSize = 0.8
    let lipCount = 3

    var mountOffset: Double { charger.diameter / 2 + 2.0 }
    let mountHoleDiameter = 2.4
    let mountHoleDepth = 5.4
    let chamferSize = 0.6
    let chinLength = 9.0

    var body: any Geometry3D {
        EnvironmentReader { e in
            let chargerDiameter = charger.diameter + e.tolerance
            let edgeWidth = 1.0
            let width = chargerDiameter + edgeWidth * 2

            Circle(diameter: width)
                .cloned { $0.translated(x: chinLength) }
                .convexHull()
                .extruded(
                    height: thickness,
                    topEdge: .chamfer(size: chamferSize),
                    bottomEdge: .chamfer(size: chamferSize),
                    method: .convexHull
                )
                .subtracting {
                    Cylinder(diameter: chargerDiameter, height: thickness)
                        .translated(z: frontThickness)

                    // Mount
                    Cylinder(diameter: mountHoleDiameter, height: mountHoleDepth + 1)
                        .translated(x: mountOffset, y: Base.stemMountScrewSpacing / 2.0, z: thickness - mountHoleDepth)
                        .symmetry(over: .y)

                    // Cable channel
                    Cylinder(diameter: charger.strainReliefDiameter, height: mountOffset + charger.strainReliefDiameter)
                        .rotated(y: 90°)
                        .translated(z: frontThickness + charger.thickness / 2)
                        .cloned { $0.translated(z: thickness) }
                        .convexHull()
                }
                .adding {
                    EdgeProfile.chamfer(size: lipSize).shape()
                        .extruded(height: chargerDiameter)
                        .rotated(x: 90°)
                        .flipped(along: .z)
                        .aligned(at: .centerY)
                        .translated(x: -chargerDiameter / 2, z: thickness)
                        .repeated(around: .z, count: lipCount)
                        .intersection {
                            Cylinder(diameter: chargerDiameter, height: thickness + 1)
                        }
                }
        }
    }
}
