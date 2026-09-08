import Cocoa

struct ClockTime {
    let hour: Int
    let minute: Int
    let second: Int
    init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.hour, .minute, .second], from: date)
        hour = c.hour!; minute = c.minute!; second = c.second!
    }
    var isPM: Bool { hour >= 12 }
    var twelveHour: Int { hour % 12 == 0 ? 12 : hour % 12 }
    var digits: [Int?] { [twelveHour >= 10 ? 1 : nil, twelveHour % 10, minute / 10, minute % 10] }
}

struct FlowerState {
    let discAngle: CGFloat
    let dotAngle: CGFloat
    init(seconds: Double) {
        // Decorative rotation: a full long/short pattern repeats every eight seconds.
        discAngle = CGFloat(seconds.truncatingRemainder(dividingBy: 64) * 5.625)
        dotAngle = CGFloat(seconds.truncatingRemainder(dividingBy: 60) / 60 * 2 * .pi)
    }

    static func breathingLotus(seconds: Double) -> NSBezierPath {
        let flower = NSBezierPath()
        let rotation = FlowerState(seconds: seconds).discAngle
        // Match the approved preview, scaled to the original flower's radius.
        for index in 0..<12 {
            let phase = seconds.truncatingRemainder(dividingBy: 10) * .pi / 5
                + Double(index % 2) * .pi
            let bloom = (1 + sin(phase)) / 2
            let length = 66 + 48 * bloom
            let width = 9 + 12 * (1 - bloom)
            let curl = 12 * sin(phase)
            let petal = NSBezierPath()
            petal.move(to: CGPoint(x: -3, y: -12))
            petal.curve(to: CGPoint(x: curl, y: -length),
                        controlPoint1: CGPoint(x: -width, y: -30),
                        controlPoint2: CGPoint(x: -width + curl, y: -length + 15))
            petal.curve(to: CGPoint(x: 3, y: -12),
                        controlPoint1: CGPoint(x: width + curl, y: -length + 15),
                        controlPoint2: CGPoint(x: width, y: -30))
            petal.close()
            petal.transform(using: AffineTransform(rotationByDegrees: CGFloat(index) * 30 + rotation))
            flower.append(petal)
        }
        flower.appendOval(in: NSRect(x: -7, y: -7, width: 14, height: 14))
        flower.transform(using: AffineTransform(scale: 40.0 / 114.0))
        return flower
    }

    static func pattern(rotation: CGFloat = 0, reversedSkew: Bool = false) -> NSBezierPath {
        let pattern = NSBezierPath()
        for index in 0..<16 {
            let long = index.isMultiple(of: 2)
            let length: CGFloat = long ? 40 : 30
            let halfWidth: CGFloat = long ? 3.4 : 2.1
            let spoke = NSBezierPath()
            // Tangentially offset roots give each ray the skew of the physical disc.
            // The tapered sides approach beside the hub instead of pointing at its centre.
            let rootX: CGFloat = reversedSkew ? -4.5 : 4.5
            spoke.move(to: CGPoint(x: rootX - 0.35, y: -2))
            spoke.line(to: CGPoint(x: -halfWidth, y: -(length - halfWidth)))
            spoke.curve(to: CGPoint(x: 0, y: -length),
                        controlPoint1: CGPoint(x: -halfWidth, y: -length),
                        controlPoint2: CGPoint(x: -halfWidth * 0.55, y: -length))
            spoke.curve(to: CGPoint(x: halfWidth, y: -(length - halfWidth)),
                        controlPoint1: CGPoint(x: halfWidth * 0.55, y: -length),
                        controlPoint2: CGPoint(x: halfWidth, y: -length))
            spoke.line(to: CGPoint(x: rootX + 0.35, y: -2))
            spoke.close()
            let transform = AffineTransform(rotationByDegrees: CGFloat(index) * 22.5 + rotation)
            spoke.transform(using: transform)
            pattern.append(spoke)

        }
        return pattern
    }
}

enum FlowerStyle: String, CaseIterable {
    case original, breathingLotus

    var title: String { self == .original ? "Original Flower" : "Breathing Lotus" }
}

enum DisplayColour: String, CaseIterable {
    case orange, ledRed, vfdBlueGreen

    var title: String {
        switch self {
        case .orange: return "Original Orange"
        case .ledRed: return "LED Red"
        case .vfdBlueGreen: return "VFD Blue-Green"
        }
    }

    var illumination: NSColor {
        switch self {
        case .orange: return NSColor(srgbRed: 1, green: 0.22, blue: 0.045, alpha: 1)
        case .ledRed: return NSColor(srgbRed: 0.88, green: 0, blue: 0.035, alpha: 1)
        case .vfdBlueGreen: return NSColor(srgbRed: 0.22, green: 1, blue: 0.78, alpha: 1)
        }
    }

    var highlight: NSColor {
        switch self {
        case .orange: return NSColor(srgbRed: 1, green: 0.38, blue: 0.12, alpha: 1)
        case .ledRed: return NSColor(srgbRed: 1, green: 0.025, blue: 0.075, alpha: 1)
        case .vfdBlueGreen: return NSColor(srgbRed: 0.61, green: 1, blue: 0.89, alpha: 1)
        }
    }

    var inactive: NSColor {
        switch self {
        case .orange: return NSColor(srgbRed: 0.13, green: 0.065, blue: 0.045, alpha: 0.24)
        case .ledRed: return NSColor(srgbRed: 0.12, green: 0.005, blue: 0.012, alpha: 0.24)
        case .vfdBlueGreen: return NSColor(srgbRed: 0.035, green: 0.13, blue: 0.10, alpha: 0.24)
        }
    }
}

final class ClockView: NSView {
    let ornamentScale: CGFloat = 1.4641
    var fullScreenPreview = false
    var isFullScreenDisplay: Bool { fullScreenPreview || window?.styleMask.contains(.fullScreen) == true }
    var date = Date()
    var displayOnly = UserDefaults.standard.bool(forKey: "displayOnly")
    var brightness: CGFloat = UserDefaults.standard.object(forKey: "dim") as? Bool == true ? 0.48 : 1
    override var isFlipped: Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }
    var displayColour = DisplayColour(rawValue: UserDefaults.standard.string(forKey: "displayColour") ?? "") ?? .orange
    var flowerStyle = FlowerStyle(rawValue: UserDefaults.standard.string(forKey: "flowerStyle") ?? "") ?? .original
    var colourNoticeUntil: TimeInterval = 0
    var illumination: NSColor { displayColour.illumination }

    func showColourNotice() {
        colourNoticeUntil = ProcessInfo.processInfo.systemUptime + 2
        needsDisplay = true
        NSAccessibility.post(element: self, notification: .announcementRequested,
                             userInfo: [.announcement: displayColour.title, .priority: NSAccessibilityPriorityLevel.medium.rawValue])
    }

    func drawColourNotice() {
        let remaining = colourNoticeUntil - ProcessInfo.processInfo.systemUptime
        guard remaining > 0 else { return }
        let alpha = min(1, remaining / 0.3)
        // Wide, chamfered vector lettering inspired by 1970s sci-fi displays.
        let glyphs: [Character: [[CGPoint]]] = [
            "A": [[.init(x:0,y:7),.init(x:0,y:1),.init(x:1,y:0),.init(x:5,y:0),.init(x:6,y:1),.init(x:6,y:7)], [.init(x:0,y:4),.init(x:6,y:4)]],
            "B": [[.init(x:0,y:0),.init(x:5,y:0),.init(x:6,y:1),.init(x:6,y:2.5),.init(x:5,y:3.5),.init(x:0,y:3.5)], [.init(x:5,y:3.5),.init(x:6,y:4.5),.init(x:6,y:6),.init(x:5,y:7),.init(x:0,y:7),.init(x:0,y:0)]],
            "D": [[.init(x:0,y:0),.init(x:4.5,y:0),.init(x:6,y:1.5),.init(x:6,y:5.5),.init(x:4.5,y:7),.init(x:0,y:7),.init(x:0,y:0)]],
            "E": [[.init(x:6,y:0),.init(x:0,y:0),.init(x:0,y:7),.init(x:6,y:7)], [.init(x:0,y:3.5),.init(x:5,y:3.5)]],
            "F": [[.init(x:6,y:0),.init(x:0,y:0),.init(x:0,y:7)], [.init(x:0,y:3.5),.init(x:5,y:3.5)]],
            "G": [[.init(x:6,y:1),.init(x:5,y:0),.init(x:1,y:0),.init(x:0,y:1),.init(x:0,y:6),.init(x:1,y:7),.init(x:6,y:7),.init(x:6,y:3.5),.init(x:3,y:3.5)]],
            "I": [[.init(x:1,y:0),.init(x:5,y:0)], [.init(x:3,y:0),.init(x:3,y:7)], [.init(x:1,y:7),.init(x:5,y:7)]],
            "L": [[.init(x:0,y:0),.init(x:0,y:7),.init(x:6,y:7)]],
            "N": [[.init(x:0,y:7),.init(x:0,y:0),.init(x:6,y:7),.init(x:6,y:0)]],
            "O": [[.init(x:1,y:0),.init(x:5,y:0),.init(x:6,y:1),.init(x:6,y:6),.init(x:5,y:7),.init(x:1,y:7),.init(x:0,y:6),.init(x:0,y:1),.init(x:1,y:0)]],
            "R": [[.init(x:0,y:7),.init(x:0,y:0),.init(x:5,y:0),.init(x:6,y:1),.init(x:6,y:2.5),.init(x:5,y:3.5),.init(x:0,y:3.5)], [.init(x:3,y:3.5),.init(x:6,y:7)]],
            "U": [[.init(x:0,y:0),.init(x:0,y:6),.init(x:1,y:7),.init(x:5,y:7),.init(x:6,y:6),.init(x:6,y:0)]],
            "V": [[.init(x:0,y:0),.init(x:0,y:3),.init(x:3,y:7),.init(x:6,y:3),.init(x:6,y:0)]],
            "-": [[.init(x:1,y:3.5),.init(x:5,y:3.5)]]
        ]
        let text = Array(displayColour.title.uppercased())
        let scale: CGFloat = 1.65
        let width = CGFloat(text.count * 9 - 3) * scale
        let origin = CGPoint(x: (isFullScreenDisplay ? 417.5 : 400) - width / 2, y: 306)
        let lettering = NSBezierPath()
        for (index, character) in text.enumerated() {
            for stroke in glyphs[character] ?? [] {
                for (pointIndex, point) in stroke.enumerated() {
                    let position = CGPoint(x: origin.x + (CGFloat(index * 9) + point.x) * scale,
                                           y: origin.y + point.y * scale)
                    if pointIndex == 0 { lettering.move(to: position) } else { lettering.line(to: position) }
                }
            }
        }
        NSGraphicsContext.saveGraphicsState()
        let glow = NSShadow()
        glow.shadowColor = illumination.withAlphaComponent(0.5 * alpha * brightness)
        glow.shadowBlurRadius = 4
        glow.shadowOffset = .zero
        glow.set()
        illumination.withAlphaComponent(alpha * brightness).setStroke()
        lettering.lineWidth = 1.2
        lettering.lineJoinStyle = .bevel
        lettering.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }

    func shape(_ rect: NSRect, radius: CGFloat, color: NSColor) {
        color.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }
    func polygon(_ points: [CGPoint]) -> NSBezierPath {
        let p = NSBezierPath(); p.move(to: points[0]); points.dropFirst().forEach { p.line(to: $0) }; p.close(); return p
    }
    func light(_ path: NSBezierPath, active: Bool = true) {
        NSGraphicsContext.saveGraphicsState()
        if active {
            let glow = NSShadow(); glow.shadowColor = illumination.withAlphaComponent(0.65 * brightness); glow.shadowBlurRadius = 9; glow.shadowOffset = .zero; glow.set()
            illumination.withAlphaComponent(brightness).setFill(); path.fill()
            NSShadow().set()
            displayColour.highlight.withAlphaComponent(0.5 * brightness).setStroke(); path.lineWidth = 0.6; path.stroke()
        } else { displayColour.inactive.setFill(); path.fill() }
        NSGraphicsContext.restoreGraphicsState()
    }
    func digit(_ number: Int?, x: CGFloat, y: CGFloat, small: Bool = false) {
        // The horizontal shutters wrap around the left corner. Each ends
        // before the right upright; dark seams separate all seven pieces.
        let segments: [[CGPoint]] = [
            [CGPoint(x: 0,y: 0), CGPoint(x: 77,y: 0), CGPoint(x: 77,y: 10),
             CGPoint(x: 10,y: 10), CGPoint(x: 10,y: 16), CGPoint(x: 0,y: 16)],
            [CGPoint(x: 80,y: 0), CGPoint(x: 90,y: 0), CGPoint(x: 90,y: 93), CGPoint(x: 80,y: 93)],
            [CGPoint(x: 80,y: 96), CGPoint(x: 90,y: 96), CGPoint(x: 90,y: 189), CGPoint(x: 80,y: 189)],
            [CGPoint(x: 0,y: 174), CGPoint(x: 10,y: 174), CGPoint(x: 10,y: 179),
             CGPoint(x: 77,y: 179), CGPoint(x: 77,y: 189), CGPoint(x: 0,y: 189)],
            [CGPoint(x: 0,y: 96), CGPoint(x: 10,y: 96), CGPoint(x: 10,y: 171), CGPoint(x: 0,y: 171)],
            [CGPoint(x: 0,y: 19), CGPoint(x: 10,y: 19), CGPoint(x: 10,y: 93), CGPoint(x: 0,y: 93)],
            [CGPoint(x: 13,y: 89.5), CGPoint(x: 77,y: 89.5), CGPoint(x: 77,y: 99.5), CGPoint(x: 13,y: 99.5)]
        ]
        if small {
            if number != nil {
                for index in [1, 2] {
                    light(polygon(segments[index].map { CGPoint(x: x + $0.x - 44, y: y + $0.y) }))
                }
            }
            return
        }
        let masks = [0x3f,0x06,0x5b,0x4f,0x66,0x6d,0x7d,0x07,0x7f,0x6f]
        for (i, points) in segments.enumerated() {
            light(polygon(points.map { CGPoint(x: x + $0.x, y: y + $0.y) }),
                  active: number.map { masks[$0] & (1 << i) != 0 } ?? false)
        }
    }

    func flower(seconds: Double) {
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        // Preserve the flower placement established against the top bars.
        let ornamentCentreY: CGFloat = 112 + 50 * ornamentScale
        let ornamentTransform = NSAffineTransform()
        ornamentTransform.translateX(by: 645, yBy: ornamentCentreY)
        ornamentTransform.scale(by: ornamentScale)
        ornamentTransform.translateX(by: -645, yBy: -212)
        ornamentTransform.concat()
        let state = FlowerState(seconds: seconds)
        NSGraphicsContext.saveGraphicsState()
        let centre = NSAffineTransform()
        centre.translateX(by: 645, yBy: 212)
        centre.concat()
        switch flowerStyle {
        case .original:
            // Opposite skew inferred from the mask photograph; widths remain approximate.
            FlowerState.pattern(rotation: 1.0, reversedSkew: true).addClip()
            light(FlowerState.pattern(rotation: state.discAngle))
        case .breathingLotus:
            light(FlowerState.breathingLotus(seconds: seconds))
        }
        NSGraphicsContext.restoreGraphicsState()
        let orbitRadius: CGFloat = 46.46
        let dot = CGPoint(x: 645 + orbitRadius * sin(state.dotAngle), y: 212 - orbitRadius * cos(state.dotAngle))
        light(NSBezierPath(ovalIn: NSRect(x: dot.x - 2.2, y: dot.y - 2.2, width: 4.4, height: 4.4)))
    }
    override func draw(_ dirtyRect: NSRect) {
        let fullScreen = isFullScreenDisplay
        (fullScreen ? NSColor.black : NSColor(srgbRed: 0.075,green: 0.075,blue: 0.07,alpha: 1)).setFill()
        bounds.fill()
        NSGraphicsContext.saveGraphicsState()
        let canvas = fullScreen ? NSRect(x: 90,y: 75,width: 655,height: 245)
                                : NSRect(x: 0,y: 0,width: 800,height: displayOnly ? 405 : 570)
        let scale = min(bounds.width / canvas.width, bounds.height / canvas.height)
        let transform = NSAffineTransform()
        transform.translateX(by: (bounds.width - canvas.width * scale) / 2,
                             yBy: (bounds.height - canvas.height * scale) / 2)
        transform.scale(by: scale)
        transform.translateX(by: -canvas.minX,yBy: -canvas.minY)
        transform.concat()
        let glass = NSBezierPath()
        if !fullScreen {
        if !displayOnly {
            shape(NSRect(x: 224,y: 484,width: 352,height: 39),radius: 2,color: NSColor(white: 0.035,alpha: 1))
            let stem = polygon([CGPoint(x: 328,y: 390),CGPoint(x: 472,y: 390),CGPoint(x: 491,y: 517),CGPoint(x: 309,y: 517)])
            NSGradient(starting: NSColor(white: 0.94,alpha: 1), ending: NSColor(white: 0.74,alpha: 1))!.draw(in: stem,angle: 0)
            shape(NSRect(x: 224,y: 519,width: 352,height: 7),radius: 1,color: NSColor(white: 0.12,alpha: 1))
        }
        // KT-10B: nearly square upper shoulders, tapered sides, broad lower corners.
        let body = NSBezierPath()
        body.move(to: CGPoint(x: 37,y: 24))
        body.line(to: CGPoint(x: 763,y: 24))
        body.curve(to: CGPoint(x: 776,y: 38),controlPoint1: CGPoint(x: 773,y: 24),controlPoint2: CGPoint(x: 778,y: 29))
        body.line(to: CGPoint(x: 747,y: 355))
        body.curve(to: CGPoint(x: 699,y: 410),controlPoint1: CGPoint(x: 744,y: 394),controlPoint2: CGPoint(x: 730,y: 410))
        body.line(to: CGPoint(x: 101,y: 410))
        body.curve(to: CGPoint(x: 53,y: 355),controlPoint1: CGPoint(x: 70,y: 410),controlPoint2: CGPoint(x: 56,y: 394))
        body.line(to: CGPoint(x: 24,y: 38))
        body.curve(to: CGPoint(x: 37,y: 24),controlPoint1: CGPoint(x: 22,y: 29),controlPoint2: CGPoint(x: 27,y: 24))
        body.close()
        NSGradient(starting: NSColor(srgbRed: 0.96,green: 0.95,blue: 0.9,alpha: 1),ending: NSColor(srgbRed: 0.76,green: 0.76,blue: 0.70,alpha: 1))!.draw(in: body,angle: 90)
        glass.move(to: CGPoint(x: 47,y: 43))
        glass.line(to: CGPoint(x: 753,y: 43))
        glass.line(to: CGPoint(x: 727,y: 325))
        glass.curve(to: CGPoint(x: 695,y: 355),controlPoint1: CGPoint(x: 725,y: 347),controlPoint2: CGPoint(x: 716,y: 355))
        glass.line(to: CGPoint(x: 105,y: 355))
        glass.curve(to: CGPoint(x: 73,y: 325),controlPoint1: CGPoint(x: 84,y: 355),controlPoint2: CGPoint(x: 75,y: 347))
        glass.close()
        NSColor(white: 0.02,alpha: 1).setStroke(); glass.lineWidth = 6; glass.stroke()
        NSGradient(starting: NSColor(srgbRed: 0.065,green: 0.061,blue: 0.047,alpha: 1),ending: NSColor(white: 0.012,alpha: 1))!.draw(in: glass,angle: 90)
        }
        let time = ClockTime(date)
        let d = time.digits
        digit(d[0],x: 88,y: 102,small: true); digit(d[1],x: 153,y: 102)
        digit(d[2],x: 365,y: 102); digit(d[3],x: 477,y: 102)
        for y: CGFloat in [164,234] { light(NSBezierPath(rect: NSRect(x: 290,y: y,width: 12,height: 7))) }
        NSGraphicsContext.saveGraphicsState()
        let indicatorGlow = NSShadow()
        indicatorGlow.shadowColor = illumination.withAlphaComponent(0.45 * brightness)
        indicatorGlow.shadowBlurRadius = 5
        indicatorGlow.shadowOffset = .zero
        indicatorGlow.set()
        let indicator = (time.isPM ? "PM" : "AM") as NSString
        let indicatorFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        let indicatorAttributes: [NSAttributedString.Key: Any] = [
            .font: indicatorFont, .foregroundColor: illumination.withAlphaComponent(brightness)]
        // Align with the leftmost petal extent and the bottom of the digits.
        indicator.draw(at: CGPoint(x: 645 - 40 * ornamentScale,
                                   y: 291 - indicatorFont.ascender),
                       withAttributes: indicatorAttributes)
        NSGraphicsContext.restoreGraphicsState()
        flower(seconds: date.timeIntervalSince1970)
        drawColourNotice()
        if !fullScreen {
        NSGraphicsContext.saveGraphicsState(); glass.addClip()
        NSColor(white: 1,alpha: 0.025).setFill()
        polygon([CGPoint(x: 49,y: 43),CGPoint(x: 751,y: 43),CGPoint(x: 751,y: 67),CGPoint(x: 49,y: 150)]).fill()
        NSGraphicsContext.restoreGraphicsState()
        let badge = NSRect(x: 568,y: 371,width: 118,height: 26)
        shape(badge,radius: 1,color: NSColor(srgbRed: 0.19,green: 0.13,blue: 0.10,alpha: 1))
        let badgeText = "LUMITIME" as NSString
        let badgeFont = NSFont(name: "HelveticaNeue-CondensedBold",size: 21) ?? NSFont.boldSystemFont(ofSize: 19)
        let badgeAttributes: [NSAttributedString.Key: Any] = [.font: badgeFont,.foregroundColor: NSColor(white: 0.94,alpha: 1)]
        let badgeSize = badgeText.size(withAttributes: badgeAttributes)
        badgeText.draw(at: CGPoint(x: badge.midX - badgeSize.width / 2,
                                  y: badge.midY + badgeFont.capHeight / 2 - badgeFont.ascender),
                       withAttributes: badgeAttributes)
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let clock = ClockView()
    var timer: Timer?
    let colourMenu = NSMenu(title: "Display Colour")
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let iconURL = Bundle.main.url(forResource: "Lumitime", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 800,height: 570),styleMask: [.titled,.closable,.miniaturizable,.resizable],backing: .buffered,defer: false)
        window.title = "Lumitime KT-10B"; window.backgroundColor = NSColor(white: 0.075,alpha: 1)
        window.titlebarAppearsTransparent = true; window.minSize = NSSize(width: 400,height: 310)
        window.contentView = clock; window.setFrameAutosaveName("LumitimeWindow")
        window.center(); window.makeKeyAndOrderFront(nil)
        window.level = UserDefaults.standard.bool(forKey: "onTop") ? .floating : .normal
        clock.setAccessibilityElement(true); clock.setAccessibilityRole(.staticText)
        update()
        timer = Timer(timeInterval: 1.0 / 30,target: self,selector: #selector(update),userInfo: nil,repeats: true)
        RunLoop.main.add(timer!,forMode: .common)
        let menu = NSMenu(); let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Lumitime",action: #selector(about),keyEquivalent: "")
        appMenu.addItem(.separator()); appMenu.addItem(withTitle: "Quit Lumitime",action: #selector(NSApplication.terminate(_:)),keyEquivalent: "q")
        let viewItem = NSMenuItem(); viewItem.title = "View"; menu.addItem(viewItem)
        let viewMenu = NSMenu(title: "View"); viewItem.submenu = viewMenu
        for (title,selector,key,on) in [("Keep on Top",#selector(onTop),"t",window.level == .floating),("Display Only",#selector(displayOnly),"d",clock.displayOnly),("Dim Display",#selector(dim),"b",clock.brightness < 1)] {
            let item = viewMenu.addItem(withTitle: title,action: selector,keyEquivalent: key); item.target = self; item.state = on ? .on : .off
        }
        viewMenu.addItem(withTitle: "Enter Full Screen",action: #selector(fullScreen),keyEquivalent: "f").target = self
        let colourItem = viewMenu.addItem(withTitle: "Display Colour", action: nil, keyEquivalent: "")
        colourItem.submenu = colourMenu
        for colour in DisplayColour.allCases {
            let item = colourMenu.addItem(withTitle: colour.title, action: #selector(changeDisplayColour(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = colour.rawValue
            item.state = clock.displayColour == colour ? .on : .off
        }
        let cycleItem = viewMenu.addItem(withTitle: "Cycle Display Colour", action: #selector(cycleDisplayColour), keyEquivalent: "c")
        cycleItem.keyEquivalentModifierMask = [.command, .shift]
        cycleItem.target = self
        let flowerItem = viewMenu.addItem(withTitle: "Flower", action: nil, keyEquivalent: "")
        let flowerMenu = NSMenu(title: "Flower")
        flowerItem.submenu = flowerMenu
        for style in FlowerStyle.allCases {
            let item = flowerMenu.addItem(withTitle: style.title, action: #selector(changeFlowerStyle(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = style.rawValue
            item.state = clock.flowerStyle == style ? .on : .off
        }
        NSApp.mainMenu = menu; NSApp.activate(ignoringOtherApps: true)
    }
    @objc func update() { clock.date = Date(); clock.needsDisplay = true; clock.setAccessibilityValue(clock.date.formatted(date: .omitted,time: .standard)) }
    @objc func onTop(_ sender: NSMenuItem) { sender.state = sender.state == .on ? .off : .on; window.level = sender.state == .on ? .floating : .normal; UserDefaults.standard.set(sender.state == .on,forKey: "onTop") }
    @objc func displayOnly(_ sender: NSMenuItem) { clock.displayOnly.toggle(); sender.state = clock.displayOnly ? .on : .off; UserDefaults.standard.set(clock.displayOnly,forKey: "displayOnly"); clock.needsDisplay = true }
    @objc func dim(_ sender: NSMenuItem) { sender.state = sender.state == .on ? .off : .on; clock.brightness = sender.state == .on ? 0.48 : 1; UserDefaults.standard.set(sender.state == .on,forKey: "dim"); clock.needsDisplay = true }
    @objc func changeDisplayColour(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let colour = DisplayColour(rawValue: rawValue) else { return }
        applyDisplayColour(colour)
    }
    @objc func cycleDisplayColour() {
        let colours = DisplayColour.allCases
        let index = colours.firstIndex(of: clock.displayColour) ?? 0
        applyDisplayColour(colours[(index + 1) % colours.count])
    }
    func applyDisplayColour(_ colour: DisplayColour) {
        clock.displayColour = colour
        UserDefaults.standard.set(colour.rawValue, forKey: "displayColour")
        for item in colourMenu.items {
            item.state = (item.representedObject as? String) == colour.rawValue ? .on : .off
        }
        clock.showColourNotice()
    }
    @objc func changeFlowerStyle(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let style = FlowerStyle(rawValue: rawValue) else { return }
        clock.flowerStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "flowerStyle")
        for item in sender.menu?.items ?? [] {
            item.state = (item.representedObject as? String) == style.rawValue ? .on : .off
        }
        clock.needsDisplay = true
    }
    @objc func fullScreen() { window.toggleFullScreen(nil) }
    @objc func about() { NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "Lumitime",.applicationVersion: "1.0",.credits: NSAttributedString(string: "A native tribute to the Tamura Lumitime KT-10B.\nCustom illuminated shutter digits and a flower seconds display.\nBlooming petals and a clockwise seconds dot, based on the video reference.")]) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

if CommandLine.arguments.contains("--self-test") {
    var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(secondsFromGMT: 0)!
    for h in 0..<24 { for m in 0..<60 { for s in [0,9,10,59] {
        let date = cal.date(from: DateComponents(year: 2026,month: 1,day: 1,hour: h,minute: m,second: s))!
        let t = ClockTime(date,calendar: cal)
        precondition(t.twelveHour == (h % 12 == 0 ? 12 : h % 12)); precondition(t.minute == m && t.second == s)
        precondition(t.isPM == (h >= 12))
        precondition(t.digits[2] == m / 10 && t.digits[3] == m % 10)
    } } }
    for tick in 0..<1800 {
        let seconds = Double(tick) / 30
        let a = FlowerState(seconds: seconds), b = FlowerState(seconds: seconds + 64)
        precondition(abs(a.discAngle - b.discAngle) < 0.000001)
        precondition(a.discAngle >= 0 && a.discAngle < 360)
    }
    let mask = FlowerState.pattern(rotation: 1.0)
    let aligned = FlowerState.pattern(rotation: 46.0)
    let offset = FlowerState.pattern(rotation: 12.25)
    var fullArea = 0, offsetArea = 0, alignedArea = 0
    for x in -80...80 { for y in -80...80 {
        let point = CGPoint(x: Double(x) / 2, y: Double(y) / 2)
        if mask.contains(point) {
            if aligned.contains(point) { alignedArea += 1 }
            fullArea += 1
            if offset.contains(point) { offsetArea += 1 }
        }
    } }
    precondition(fullArea > 0 && offsetArea < fullArea / 4)
    precondition(abs(fullArea - alignedArea) < fullArea / 100)
    precondition(abs(sin(FlowerState(seconds: 15).dotAngle) - 1) < 0.000001)
    print("Passed 5,760 clock cases, 1,800 disc rotation samples, and mask overlap checks.")
} else if let i = CommandLine.arguments.firstIndex(of: "--snapshot"), i + 1 < CommandLine.arguments.count {
    _ = NSApplication.shared
    let view = ClockView(frame: NSRect(x: 0,y: 0,width: 1000,height: 713))
    if let colourIndex = CommandLine.arguments.firstIndex(of: "--colour"), colourIndex + 1 < CommandLine.arguments.count,
       let colour = DisplayColour(rawValue: CommandLine.arguments[colourIndex + 1]) {
        view.displayColour = colour
    }
    if let styleIndex = CommandLine.arguments.firstIndex(of: "--flower"), styleIndex + 1 < CommandLine.arguments.count,
       let style = FlowerStyle(rawValue: CommandLine.arguments[styleIndex + 1]) {
        view.flowerStyle = style
    }
    if CommandLine.arguments.contains("--colour-notice") { view.showColourNotice() }
    view.fullScreenPreview = CommandLine.arguments.contains("--full-screen")
    view.date = Calendar.current.date(from: DateComponents(year: 2026,month: 9,day: 5,hour: 10,minute: 28,second: 6))!
    if let phaseIndex = CommandLine.arguments.firstIndex(of: "--seconds"), phaseIndex + 1 < CommandLine.arguments.count,
       let seconds = Double(CommandLine.arguments[phaseIndex + 1]) {
        view.date = Date(timeIntervalSince1970: floor(view.date.timeIntervalSince1970 / 60) * 60 + seconds)
    }
    let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds)!
    view.cacheDisplay(in: view.bounds,to: bitmap)
    try bitmap.representation(using: .png,properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
} else {
    let app = NSApplication.shared; let delegate = AppDelegate(); app.delegate = delegate; app.setActivationPolicy(.regular); app.run()
}
