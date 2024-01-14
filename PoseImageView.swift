/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a view that visualizes the detected poses.
*/

import UIKit

//@IBDesignable
var ang = false
class PoseImageView: UIImageView {
 
    /// A data structure used to describe a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
        
        let angle = 0
    }

    /// An array of joint-pairs that define the lines of a pose's wireframe drawing.
    static let jointSegments = [
        // The connected joints that are on the left side of the body.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // The connected joints that are on the right side of the body.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // The connected joints that cross over the body.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip),
        //darran's
        JointSegment(jointA: .rightWrist, jointB: .rightShoulder)
        
    ]

    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemPink

        var ang: Bool = false {
            didSet {
                segmentColor = ang ? UIColor.systemTeal: UIColor.systemPink
            }
        }    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

    // MARK: - Rendering methods

    /// Returns an image showing the detected poses.
    ///
    /// - parameters:
    ///     - poses: An array of detected poses.
    ///     - frame: The image used to detect the poses and used as the background for the returned image.
    func show(poses: [Pose], on frame: CGImage) {
        
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()

        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)

        let dstImage = renderer.image { rendererContext in
            // Draw the current frame as the background for the new image.
            draw(image: frame, in: rendererContext.cgContext)

            for pose in poses {
                let rightElbow = pose[Joint.Name.rightElbow]
                let rightShoulder = pose[Joint.Name.rightShoulder]
                let rightWrist = pose[Joint.Name.rightWrist]

                if rightElbow.isValid, rightShoulder.isValid, rightWrist.isValid {
                    let vectorElbowShoulder = CGPoint(x: rightShoulder.position.x - rightElbow.position.x,
                                                      y: rightShoulder.position.y - rightElbow.position.y)
                    let vectorElbowWrist = CGPoint(x: rightWrist.position.x - rightElbow.position.x,
                                                   y: rightWrist.position.y - rightElbow.position.y)
                    
                    let dotProduct = vectorElbowShoulder.x * vectorElbowWrist.x + vectorElbowShoulder.y * vectorElbowWrist.y
                    let magnitudeProduct = sqrt(vectorElbowShoulder.x * vectorElbowShoulder.x + vectorElbowShoulder.y * vectorElbowShoulder.y) * sqrt(vectorElbowWrist.x * vectorElbowWrist.x + vectorElbowWrist.y * vectorElbowWrist.y)
                    
                    let angle = acos(dotProduct / magnitudeProduct) * (180.0 / .pi) // angle in degrees
                    
                    print("Angle between right shoulder and right wrist: \(angle)")
                    
                    // Coloring right shoulder to right wrist line in green
                    if angle > 30 { // adjust the angle as per your requirement
                        ang = true
                    } else {
                        ang = false
                    }
                }
                // Draw the segment lines.
                for segment in PoseImageView.jointSegments {
                    
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]

                    guard jointA.isValid, jointB.isValid else {
                        continue
                    }
//                    if(jointA == "rightWrist" && jointB == "leftWrist")
//                    {
                        
                        drawLine(from: jointA,
                                 to: jointB,
                                 in: rendererContext.cgContext)
//                    }
                    
                }

                // Draw the joints as circles above the segment lines.
                for joint in pose.joints.values.filter({ $0.isValid }) {
                    draw(circle: joint, in: rendererContext.cgContext)
                }
            }
        }

        image = dstImage
    }

    /// Vertically flips and draws the given image.
    ///
    /// - parameters:
    ///     - image: The image to draw onto the context (vertically flipped).
    ///     - cgContext: The rendering context.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        // The given image is assumed to be upside down; therefore, the context
        // is flipped before rendering the image.
        cgContext.scaleBy(x: 1.0, y: -1.0)
        // Render the image, adjusting for the scale transformation performed above.
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
        
    }

    /// Draws a line between two joints.
    ///
    /// - parameters:
    ///     - parentJoint: A valid joint whose position is used as the start position of the line.
    ///     - childJoint: A valid joint whose position is used as the end of the line.
    ///     - cgContext: The rendering context.
    func drawLine(from parentJoint: Joint,
                  to childJoint: Joint,
                  in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)

        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    /// Draw a circle in the location of the given joint.
    ///
    /// - parameters:
    ///     - circle: A valid joint whose position is used as the circle's center.
    ///     - cgContext: The rendering context.
    private func draw(circle joint: Joint, in cgContext: CGContext) {
        cgContext.setFillColor(jointColor.cgColor)

        let rectangle = CGRect(x: joint.position.x - jointRadius, y: joint.position.y - jointRadius,
                               width: jointRadius * 2, height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }
}
