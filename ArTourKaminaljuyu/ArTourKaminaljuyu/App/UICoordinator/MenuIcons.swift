//
//  MenuIcons.swift
//  ArTourKaminaljuyu
//
//  Created by Alejandra  Salvatierra on 14/05/26.
//

import SwiftUI

// MARK: - Guided Tour Icon (Compass)
struct GuidedTourIcon: View {
    var size: CGFloat = 32

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 24

            // Outer circle
            let outerCircle = Path(ellipseIn: CGRect(x: 2*s, y: 2*s, width: 20*s, height: 20*s))
            context.fill(outerCircle, with: .color(Color(hex: "#ECEBC8")))
            context.stroke(outerCircle, with: .color(Color(hex: "#D25B31")), lineWidth: 2*s)

            // North needle
            var northNeedle = Path()
            northNeedle.move(to: CGPoint(x: 12*s, y: 6*s))
            northNeedle.addLine(to: CGPoint(x: 10*s, y: 12*s))
            northNeedle.addLine(to: CGPoint(x: 12*s, y: 11*s))
            northNeedle.addLine(to: CGPoint(x: 14*s, y: 12*s))
            northNeedle.closeSubpath()
            context.fill(northNeedle, with: .color(Color(hex: "#D25B31")))

            // South needle
            var southNeedle = Path()
            southNeedle.move(to: CGPoint(x: 12*s, y: 18*s))
            southNeedle.addLine(to: CGPoint(x: 14*s, y: 12*s))
            southNeedle.addLine(to: CGPoint(x: 12*s, y: 13*s))
            southNeedle.addLine(to: CGPoint(x: 10*s, y: 12*s))
            southNeedle.closeSubpath()
            context.fill(southNeedle, with: .color(Color(hex: "#E6B75C")))

            // Center dot
            let center = Path(ellipseIn: CGRect(x: 10.5*s, y: 10.5*s, width: 3*s, height: 3*s))
            context.fill(center, with: .color(Color(hex: "#E2BF9B")))

            // Cardinal marks
            var marks = Path()
            marks.move(to: CGPoint(x: 12*s, y: 3*s)); marks.addLine(to: CGPoint(x: 12*s, y: 5*s))
            marks.move(to: CGPoint(x: 12*s, y: 19*s)); marks.addLine(to: CGPoint(x: 12*s, y: 21*s))
            marks.move(to: CGPoint(x: 3*s, y: 12*s)); marks.addLine(to: CGPoint(x: 5*s, y: 12*s))
            marks.move(to: CGPoint(x: 19*s, y: 12*s)); marks.addLine(to: CGPoint(x: 21*s, y: 12*s))
            context.stroke(marks, with: .color(Color(hex: "#D25B31")), lineWidth: s)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Free Tour Icon (Map with markers)
struct FreeTourIcon: View {
    var size: CGFloat = 32

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 24

            // Map base
            let mapBase = Path(CGRect(x: 4*s, y: 4*s, width: 16*s, height: 16*s))
            context.fill(mapBase, with: .color(Color(hex: "#ECEBC8")))
            context.stroke(mapBase, with: .color(Color(hex: "#D25B31")), lineWidth: 1.5*s)

            // Location dots
            let dot1 = Path(ellipseIn: CGRect(x: 7*s, y: 8*s, width: 2*s, height: 2*s))
            context.fill(dot1, with: .color(Color(hex: "#D25B31")))
            let dot2 = Path(ellipseIn: CGRect(x: 15*s, y: 8*s, width: 2*s, height: 2*s))
            context.fill(dot2, with: .color(Color(hex: "#E6B75C")))
            let dot3 = Path(ellipseIn: CGRect(x: 7*s, y: 16*s, width: 2*s, height: 2*s))
            context.fill(dot3, with: .color(Color(hex: "#E2BF9B")))
            let dot4 = Path(ellipseIn: CGRect(x: 15*s, y: 16*s, width: 2*s, height: 2*s))
            context.fill(dot4, with: .color(Color(hex: "#D25B31")))

            // Connection lines
            var lines = Path()
            lines.move(to: CGPoint(x: 8*s, y: 9*s)); lines.addLine(to: CGPoint(x: 16*s, y: 9*s))
            lines.move(to: CGPoint(x: 8*s, y: 17*s)); lines.addLine(to: CGPoint(x: 16*s, y: 17*s))
            lines.move(to: CGPoint(x: 9*s, y: 8*s)); lines.addLine(to: CGPoint(x: 9*s, y: 16*s))
            lines.move(to: CGPoint(x: 15*s, y: 8*s)); lines.addLine(to: CGPoint(x: 15*s, y: 16*s))
            context.stroke(lines, with: .color(Color(hex: "#E6B75C")), lineWidth: s)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Instructions Icon (Scroll with lines)
struct InstructionsIcon: View {
    var size: CGFloat = 32

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 24

            // Scroll base
            var scroll = Path()
            scroll.move(to: CGPoint(x: 6*s, y: 3*s))
            scroll.addLine(to: CGPoint(x: 18*s, y: 3*s))
            scroll.addQuadCurve(to: CGPoint(x: 20*s, y: 5*s), control: CGPoint(x: 20*s, y: 3*s))
            scroll.addLine(to: CGPoint(x: 20*s, y: 19*s))
            scroll.addQuadCurve(to: CGPoint(x: 18*s, y: 21*s), control: CGPoint(x: 20*s, y: 21*s))
            scroll.addLine(to: CGPoint(x: 6*s, y: 21*s))
            scroll.addQuadCurve(to: CGPoint(x: 4*s, y: 19*s), control: CGPoint(x: 4*s, y: 21*s))
            scroll.addLine(to: CGPoint(x: 4*s, y: 5*s))
            scroll.addQuadCurve(to: CGPoint(x: 6*s, y: 3*s), control: CGPoint(x: 4*s, y: 3*s))
            context.fill(scroll, with: .color(Color(hex: "#ECEBC8")))
            context.stroke(scroll, with: .color(Color(hex: "#D25B31")), lineWidth: 1.5*s)

            // Text lines
            var lines = Path()
            lines.move(to: CGPoint(x: 7*s, y: 7*s)); lines.addLine(to: CGPoint(x: 17*s, y: 7*s))
            lines.move(to: CGPoint(x: 7*s, y: 10*s)); lines.addLine(to: CGPoint(x: 15*s, y: 10*s))
            lines.move(to: CGPoint(x: 7*s, y: 13*s)); lines.addLine(to: CGPoint(x: 17*s, y: 13*s))
            lines.move(to: CGPoint(x: 7*s, y: 16*s)); lines.addLine(to: CGPoint(x: 13*s, y: 16*s))
            context.stroke(lines, with: .color(Color(hex: "#E6B75C")), lineWidth: 1.5*s)

            // Maya decorative dot
            let dot = Path(ellipseIn: CGRect(x: 14*s, y: 15*s, width: 2*s, height: 2*s))
            context.fill(dot, with: .color(Color(hex: "#D25B31")))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Terms Icon (Document with seal)
struct TermsIcon: View {
    var size: CGFloat = 32

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 24

            // Document base
            var doc = Path()
            doc.move(to: CGPoint(x: 5*s, y: 2*s))
            doc.addLine(to: CGPoint(x: 15*s, y: 2*s))
            doc.addLine(to: CGPoint(x: 19*s, y: 6*s))
            doc.addLine(to: CGPoint(x: 19*s, y: 22*s))
            doc.addLine(to: CGPoint(x: 5*s, y: 22*s))
            doc.closeSubpath()
            context.fill(doc, with: .color(Color(hex: "#ECEBC8")))
            context.stroke(doc, with: .color(Color(hex: "#D25B31")), lineWidth: 1.5*s)

            // Folded corner
            var corner = Path()
            corner.move(to: CGPoint(x: 15*s, y: 2*s))
            corner.addLine(to: CGPoint(x: 15*s, y: 6*s))
            corner.addLine(to: CGPoint(x: 19*s, y: 6*s))
            context.fill(corner, with: .color(Color(hex: "#E2BF9B")))
            context.stroke(corner, with: .color(Color(hex: "#D25B31")), lineWidth: s)

            // Seal circle
            let seal = Path(ellipseIn: CGRect(x: 9*s, y: 12*s, width: 6*s, height: 6*s))
            context.fill(seal, with: .color(Color(hex: "#D25B31")))
            let sealInner = Path(ellipseIn: CGRect(x: 10.5*s, y: 13.5*s, width: 3*s, height: 3*s))
            context.fill(sealInner, with: .color(Color(hex: "#ECEBC8")))

            // Document lines
            var lines = Path()
            lines.move(to: CGPoint(x: 7*s, y: 9*s)); lines.addLine(to: CGPoint(x: 13*s, y: 9*s))
            lines.move(to: CGPoint(x: 7*s, y: 20*s)); lines.addLine(to: CGPoint(x: 17*s, y: 20*s))
            context.stroke(lines, with: .color(Color(hex: "#E6B75C")), lineWidth: s)

            // Seal cross
            var cross = Path()
            cross.move(to: CGPoint(x: 10.5*s, y: 15*s)); cross.addLine(to: CGPoint(x: 13.5*s, y: 15*s))
            cross.move(to: CGPoint(x: 12*s, y: 13.5*s)); cross.addLine(to: CGPoint(x: 12*s, y: 16.5*s))
            context.stroke(cross, with: .color(Color(hex: "#E6B75C")), lineWidth: 0.5*s)
        }
        .frame(width: size, height: size)
    }
}
