import SwiftUI

enum TrackArtwork {
    static func draw(in original: GraphicsContext, size: CGSize, game: RunnerGame) {
        var context = original
        context.scaleBy(x: size.width / 390, y: size.height / 844)
        let sky = Path(CGRect(x: 0, y: 0, width: 390, height: 844))
        context.fill(sky, with: .linearGradient(
            Gradient(colors: [Color(hex: 0x0B293B), Color(hex: 0x286377), Color(hex: 0xF4A676), Color(hex: 0x193F46)]),
            startPoint: CGPoint(x: 195, y: 0), endPoint: CGPoint(x: 195, y: 700)
        ))

        circle(context, 195, 270, 95, Color(hex: 0xFFD898).opacity(0.17))
        circle(context, 195, 270, 67, Color(hex: 0xFFD898))
        skyline(context)
        road(context, motion: game.trackMotion)

        let displayItems: [TrackItem] = game.state == .ready ? [
            TrackItem(lane: 0, kind: .train, progress: 0.51),
            TrackItem(lane: 2, kind: .barrier, progress: 0.36),
            TrackItem(lane: 1, kind: .coin, progress: 0.32),
            TrackItem(lane: 1, kind: .coin, progress: 0.48),
            TrackItem(lane: 1, kind: .coin, progress: 0.63)
        ] : game.items
        for item in displayItems.sorted(by: { $0.progress < $1.progress }) where item.progress <= 1.05 {
            draw(item, in: context)
        }

        let runnerX = 195.0 + Double(game.lane - 1) * 145
        runner(context, x: runnerX, jumping: game.jumpTime, sliding: game.slideTime, motion: game.trackMotion)
        if game.state == .finished {
            rectangle(context, CGRect(x: 0, y: 0, width: 390, height: 844), Palette.ink.opacity(0.42))
        } else if game.state == .paused {
            rectangle(context, CGRect(x: 0, y: 0, width: 390, height: 844), Palette.ink.opacity(0.35))
        }
    }

    private static func skyline(_ context: GraphicsContext) {
        let distant: [(CGFloat, CGFloat, CGFloat)] = [
            (0, 104, 69), (45, 95, 103), (102, 62, 78), (142, 80, 118),
            (207, 57, 70), (254, 87, 116), (322, 84, 82), (367, 40, 120)
        ]
        for (x, width, height) in distant {
            rectangle(context, CGRect(x: x, y: 356 - height, width: width, height: height), Color(hex: 0x366071))
            for column in 0..<Int(width / 16) {
                for row in 0..<Int(height / 18) where (column + row * 3) % 4 == 0 {
                    rectangle(context, CGRect(x: x + 8 + CGFloat(column) * 15, y: 365 - height + CGFloat(row) * 17, width: 4, height: 6), Color(hex: 0xFBC78A).opacity(0.5))
                }
            }
        }
        rectangle(context, CGRect(x: 0, y: 335, width: 72, height: 95), Color(hex: 0x173B4B))
        rectangle(context, CGRect(x: 315, y: 328, width: 75, height: 102), Color(hex: 0x173B4B))
        for index in 0..<3 {
            rectangle(context, CGRect(x: 12 + CGFloat(index) * 18, y: 351, width: 9, height: 13), Color(hex: 0xF2B477))
            rectangle(context, CGRect(x: 327 + CGFloat(index) * 19, y: 345, width: 9, height: 13), Color(hex: 0xF2B477))
        }
        rectangle(context, CGRect(x: 177, y: 306, width: 36, height: 40), Color(hex: 0x265361))
        rectangle(context, CGRect(x: 183, y: 296, width: 24, height: 11), Color(hex: 0x265361))
    }

    private static func road(_ context: GraphicsContext, motion: Double) {
        polygon(context, [CGPoint(x: 0, y: 844), CGPoint(x: 390, y: 844), CGPoint(x: 232, y: 350), CGPoint(x: 158, y: 350)], Color(hex: 0x315763))
        polygon(context, [CGPoint(x: 0, y: 844), CGPoint(x: 0, y: 414), CGPoint(x: 158, y: 350), CGPoint(x: 122, y: 844)], Color(hex: 0x244953))
        polygon(context, [CGPoint(x: 390, y: 844), CGPoint(x: 390, y: 414), CGPoint(x: 232, y: 350), CGPoint(x: 268, y: 844)], Color(hex: 0x244953))

        for lane in 0..<3 {
            let center = CGFloat(195 + (lane - 1) * 145)
            let nearLeft = center - 59
            let nearRight = center + 59
            let farCenter = CGFloat(195 + (lane - 1) * 23)
            polygon(context, [CGPoint(x: farCenter - 10, y: 353), CGPoint(x: farCenter + 10, y: 353), CGPoint(x: nearRight, y: 844), CGPoint(x: nearLeft, y: 844)], Color(hex: 0x173B47))
            line(context, from: CGPoint(x: farCenter - 8, y: 353), to: CGPoint(x: nearLeft + 12, y: 844), color: Color(hex: 0x83B7B3), width: 3)
            line(context, from: CGPoint(x: farCenter + 8, y: 353), to: CGPoint(x: nearRight - 12, y: 844), color: Color(hex: 0x83B7B3), width: 3)
        }

        for index in 0..<19 {
            let progress = (Double(index) / 19 + motion.truncatingRemainder(dividingBy: 1.0 / 19)).truncatingRemainder(dividingBy: 1)
            let y = depthY(progress)
            let spread = 24 + 143 * pow(progress, 1.18)
            let thickness = 2 + 8 * progress
            for lane in 0..<3 {
                let x = 195 + Double(lane - 1) * spread
                line(context, from: CGPoint(x: x - 13 - 42 * progress, y: y), to: CGPoint(x: x + 13 + 42 * progress, y: y), color: Color(hex: 0x557075), width: thickness)
            }
        }

        for side in [-1.0, 1.0] {
            line(context, from: CGPoint(x: 195 + side * 46, y: 356), to: CGPoint(x: 195 + side * 280, y: 844), color: Color(hex: 0xF5BB78), width: 5)
            for progress in [0.12, 0.33, 0.60, 0.92] {
                let y = depthY(progress)
                let x = 195 + side * (54 + 238 * pow(progress, 1.1))
                let height = 16 + 95 * progress
                line(context, from: CGPoint(x: x, y: y), to: CGPoint(x: x, y: y - height), color: Color(hex: 0x173B47), width: 3 + 4 * progress)
                circle(context, x, y - height, 4 + 8 * progress, Color(hex: 0xFFD98D))
                circle(context, x, y - height, 10 + 17 * progress, Color(hex: 0xFFD98D).opacity(0.17))
            }
        }
    }

    private static func draw(_ item: TrackItem, in context: GraphicsContext) {
        let progress = item.progress
        let size = 0.2 + 1.18 * pow(progress, 1.5)
        let spread = 23 + 145 * pow(progress, 1.1)
        let x = 195 + Double(item.lane - 1) * spread
        let y = depthY(progress)
        switch item.kind {
        case .coin:
            let radius = 16 * size
            circle(context, x, y - 48 * size, radius + 4 * size, Color(hex: 0xDB842F))
            circle(context, x, y - 48 * size, radius, Palette.gold)
            circle(context, x, y - 48 * size, radius * 0.67, Color(hex: 0xFFD972))
            text(context, "★", at: CGPoint(x: x, y: y - 48 * size), size: 17 * size, color: Color(hex: 0xDA822C))
        case .barrier:
            let width = 75 * size
            polygon(context, [CGPoint(x: x - width / 2, y: y), CGPoint(x: x + width / 2, y: y), CGPoint(x: x + width * 0.37, y: y - 43 * size), CGPoint(x: x - width * 0.37, y: y - 43 * size)], Color(hex: 0xF5A13E))
            for offset in [-0.22, 0.12] {
                polygon(context, [CGPoint(x: x + width * offset, y: y - 5 * size), CGPoint(x: x + width * (offset + 0.12), y: y - 5 * size), CGPoint(x: x + width * (offset + 0.27), y: y - 39 * size), CGPoint(x: x + width * (offset + 0.15), y: y - 39 * size)], Palette.cream)
            }
            rectangle(context, CGRect(x: x - width * 0.35, y: y - 48 * size, width: width * 0.7, height: 6 * size), Palette.coral)
            circle(context, x - width * 0.3, y - 25 * size, 3 * size, Palette.gold)
        case .sign:
            let width = 88 * size
            rectangle(context, CGRect(x: x - width * 0.47, y: y - 102 * size, width: 6 * size, height: 102 * size), Color(hex: 0x92D5C4))
            rectangle(context, CGRect(x: x + width * 0.4, y: y - 102 * size, width: 6 * size, height: 102 * size), Color(hex: 0x92D5C4))
            rounded(context, CGRect(x: x - width / 2, y: y - 107 * size, width: width, height: 39 * size), 5 * size, Palette.coral)
            text(context, "↓  DUCK  ↓", at: CGPoint(x: x, y: y - 88 * size), size: 13 * size, color: Palette.cream)
        case .train:
            let width = 81 * size
            let height = 130 * size
            rounded(context, CGRect(x: x - width / 2, y: y - height, width: width, height: height), 12 * size, Color(hex: 0xF4C17E))
            rounded(context, CGRect(x: x - width * 0.43, y: y - height * 0.91, width: width * 0.86, height: height * 0.45), 5 * size, Color(hex: 0x245368))
            rectangle(context, CGRect(x: x - width * 0.38, y: y - height * 0.85, width: width * 0.76, height: 3 * size), Color(hex: 0x98CDC1))
            rectangle(context, CGRect(x: x - width / 2, y: y - height * 0.35, width: width, height: 15 * size), Palette.coral)
            circle(context, x - width * 0.29, y - 21 * size, 7 * size, Palette.cream)
            circle(context, x + width * 0.29, y - 21 * size, 7 * size, Palette.cream)
            rounded(context, CGRect(x: x - 16 * size, y: y - 38 * size, width: 32 * size, height: 13 * size), 3 * size, Color(hex: 0x245368))
        }
    }

    private static func runner(_ context: GraphicsContext, x: Double, jumping: Double, sliding: Double, motion: Double) {
        let jumpOffset = jumping > 0 ? sin((0.82 - jumping) / 0.82 * .pi) * 83 : 0
        let bob = sliding > 0 ? 0 : sin(motion * 25) * 3
        let ground = 761.0 - jumpOffset + bob
        let stretch = sliding > 0 ? 0.62 : 1.0
        ellipse(context, CGRect(x: x - 31, y: 763, width: 62, height: 12), Palette.ink.opacity(0.35))

        polygon(context, [CGPoint(x: x - 19, y: ground - 54 * stretch), CGPoint(x: x - 1, y: ground - 55 * stretch), CGPoint(x: x - 11, y: ground - 12), CGPoint(x: x - 26, y: ground - 10)], Color(hex: 0x243B59))
        polygon(context, [CGPoint(x: x + 2, y: ground - 55 * stretch), CGPoint(x: x + 19, y: ground - 52 * stretch), CGPoint(x: x + 25, y: ground - 12), CGPoint(x: x + 9, y: ground - 10)], Color(hex: 0x1A304D))
        rounded(context, CGRect(x: x - 30, y: ground - 15, width: 28, height: 13), 6, Palette.cream)
        rounded(context, CGRect(x: x + 6, y: ground - 14, width: 29, height: 12), 6, Palette.mint)

        rounded(context, CGRect(x: x - 32, y: ground - 108 * stretch, width: 19, height: 48 * stretch), 8, Color(hex: 0xD75244))
        rounded(context, CGRect(x: x + 13, y: ground - 108 * stretch, width: 19, height: 48 * stretch), 8, Color(hex: 0xD75244))
        circle(context, x - 23, ground - 62 * stretch, 8, Color(hex: 0xE5A675))
        circle(context, x + 25, ground - 62 * stretch, 8, Color(hex: 0xE5A675))
        rounded(context, CGRect(x: x - 26, y: ground - 115 * stretch, width: 52, height: 65 * stretch), 17, Palette.coral)
        rounded(context, CGRect(x: x - 15, y: ground - 90 * stretch, width: 30, height: 26 * stretch), 8, Color(hex: 0xE55449))
        line(context, from: CGPoint(x: x - 6, y: ground - 113 * stretch), to: CGPoint(x: x - 6, y: ground - 83 * stretch), color: Palette.cream, width: 2)
        line(context, from: CGPoint(x: x + 7, y: ground - 113 * stretch), to: CGPoint(x: x + 7, y: ground - 83 * stretch), color: Palette.cream, width: 2)

        circle(context, x, ground - 134 * stretch, 26, Color(hex: 0xE8AC7C))
        polygon(context, [CGPoint(x: x - 27, y: ground - 139 * stretch), CGPoint(x: x - 22, y: ground - 160 * stretch), CGPoint(x: x + 5, y: ground - 166 * stretch), CGPoint(x: x + 26, y: ground - 152 * stretch), CGPoint(x: x + 26, y: ground - 139 * stretch), CGPoint(x: x + 5, y: ground - 148 * stretch)], Color(hex: 0x192C3D))
        rounded(context, CGRect(x: x - 22, y: ground - 155 * stretch, width: 47, height: 12), 6, Color(hex: 0x192C3D))
        circle(context, x - 8, ground - 132 * stretch, 2.3, Palette.ink)
        circle(context, x + 10, ground - 132 * stretch, 2.3, Palette.ink)
        line(context, from: CGPoint(x: x - 4, y: ground - 121 * stretch), to: CGPoint(x: x + 7, y: ground - 122 * stretch), color: Color(hex: 0xA9554C), width: 2)
    }

    private static func depthY(_ progress: Double) -> Double {
        355 + pow(max(0, progress), 1.65) * 480
    }

    private static func rectangle(_ context: GraphicsContext, _ rect: CGRect, _ color: Color) {
        context.fill(Path(rect), with: .color(color))
    }

    private static func rounded(_ context: GraphicsContext, _ rect: CGRect, _ radius: CGFloat, _ color: Color) {
        context.fill(Path(roundedRect: rect, cornerRadius: radius), with: .color(color))
    }

    private static func ellipse(_ context: GraphicsContext, _ rect: CGRect, _ color: Color) {
        context.fill(Path(ellipseIn: rect), with: .color(color))
    }

    private static func circle(_ context: GraphicsContext, _ x: Double, _ y: Double, _ radius: Double, _ color: Color) {
        ellipse(context, CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2), color)
    }

    private static func polygon(_ context: GraphicsContext, _ points: [CGPoint], _ color: Color) {
        var path = Path()
        guard let first = points.first else { return }
        path.move(to: first)
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }

    private static func line(_ context: GraphicsContext, from start: CGPoint, to end: CGPoint, color: Color, width: Double) {
        var path = Path()
        path.move(to: start)
        path.addLine(to: end)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    private static func text(_ context: GraphicsContext, _ value: String, at point: CGPoint, size: Double, color: Color) {
        context.draw(Text(value).font(.system(size: size, weight: .black, design: .rounded)).foregroundColor(color), at: point)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}
