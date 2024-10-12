import Foundation
import SwiftSCAD
import Helical

struct Base: Shape3D {
    let charger: Charger
    let useWeightNuts: Bool

    let diameter = 80.0
    let thickness = 2.0
    let curveAmount = 8.0

    let stemInnerDiameter = 13.0
    let stemWallThickness = 1.0
    var stemOuterDiameter: Double { stemInnerDiameter + 2 * stemWallThickness }
    let stemBaseHeight = 8.0

    var stemBottom: Double { thickness + curveAmount + stemBaseHeight }
    var basePath: BezierPath2D {
        BezierPath2D(startPoint: [-stemInnerDiameter / 2, 0])
            .addingCurve([-diameter / 2, 0])
            .addingCurve([-diameter / 2, thickness])
            .addingCurve(
                [-diameter / 2, thickness + curveAmount],
                [-stemOuterDiameter / 2, thickness + curveAmount],
                [-stemOuterDiameter / 2, stemBottom]
            )
            .addingCurve([-stemInnerDiameter / 2, stemBottom])
    }

    let stemStraightLength = 1.0
    var stemPath: BezierPath3D {
        BezierPath3D(startPoint: .zero)
            .addingCurve([0, 0, stemStraightLength])
            .addingCurve(
                [0, 0, 57],
                [-20, 0, 70]
            )
    }

    static let stemMountScrewSpacing = 21.0
    let stemMountScrewPostDiameter = 10.0
    let stemMountBaseHeight = 4.0
    let stemMountBaseRadius = 2.0
    let stemMountBaseTopOffset = -9.0
    let stemMountLength = 25.0

    // Nuts for weight
    let nutThread = ScrewThread.m8
    let nutDiameter = 16.0
    let nutHeight = 6.8
    let nutCount = 6

    // Helical doesn't support screws with non-uniform (pointy) shapes so let's approximate a
    // DIN 7982C 2.9x9.5 self-tapping screw which works fine for making a clearance hole
    let mountBolt = Bolt(
        thread: .m3,
        length: 9.5,
        shankLength: 0,
        headShape: CountersunkBoltHeadShape(countersink: .init(angle: 80°, topDiameter: 5.5), boltDiameter: 3)
    )

    func stemEndTransform(in environment: Environment) -> AffineTransform3D {
        stemPath.transform(at: stemPath.positionRange.upperBound, facets: environment.facets)
    }

    var body: any Geometry3D {
        Polygon(basePath)
            .extruded()
            .adding {
                // Stem
                Circle(diameter: stemOuterDiameter)
                    .usingDefaultFacets()
                    .extruded(along: stemPath)
                    .usingFacets(minAngle: 10°, minSize: 1)
                    .adding {
                        EnvironmentReader { e in
                            mount
                                .transformed(stemEndTransform(in: e))
                        }
                    }
                    .subtracting {
                        Circle(diameter: stemInnerDiameter)
                            .usingDefaultFacets()
                            .extruded(along: stemPath, in: 0...stemPath.positionRange.upperBound + 0.03)
                            .usingFacets(minAngle: 10°, minSize: 1)
                    }
                    .translated(z: stemBottom)
            }
            .subtracting {
                // Base cable channel
                Teardrop(diameter: charger.cableDiameter, style: .bridged)
                    .extruded(height: diameter)
                    .rotated(y: 90°)
                    .aligned(at: .bottom)
                    .translated(z: 0.4)
                Box([diameter, charger.cableDiameter - 0.3, charger.cableDiameter])
                    .aligned(at: .centerY)
                    .translated(z: -1)

                // Nut weights
                if useWeightNuts {
                    Cylinder(diameter: nutDiameter, height: nutHeight)
                        .subtracting {
                            Screw(thread: nutThread, length: nutHeight + 0.1)
                                .applyingBottomEdgeProfile(.chamfer(size: nutThread.depth), method: .convexHull) {
                                    Circle(diameter: nutThread.majorDiameter)
                                }
                        }
                        .translated(y: stemInnerDiameter / 2 + nutDiameter / 2 + 7)
                        .repeated(around: .z, count: nutCount)
                }
            }
            .definingNaturalUpDirection()

    }

    var mount: any Geometry3D {
        Circle(diameter: stemOuterDiameter)
            .adding {
                Circle(diameter: stemMountScrewPostDiameter)
                    .translated(y: Self.stemMountScrewSpacing / 2)
                    .symmetry(over: .y)
            }
            .convexHull()
            .extruded(height: stemMountBaseHeight, bottomEdge: .fillet(radius: stemMountBaseRadius), method: .convexHull)
            .aligned(at: .top)
            .adding {
                Cylinder(diameter: 1.0, height: 1)
                    .translated(x: stemMountBaseTopOffset, z: -stemMountLength)
            }
            .convexHull()
            .subtracting {
                mountBolt.clearanceHole(recessedHead: true)
                    .translated(y: Self.stemMountScrewSpacing / 2, z: -stemMountBaseHeight)
                    .symmetry(over: .y)
                    .withTeardropOverhang(.bridged)
            }
    }

    func attaching(@UnionBuilder3D attachment: @escaping () -> any Geometry3D) -> any Geometry3D {
        adding {
            EnvironmentReader { e in
                attachment()
                    .transformed(stemEndTransform(in: e))
                    .translated(z: stemBottom)
            }
        }
    }
}
