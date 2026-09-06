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

    static func pattern(rotation: CGFloat = 0, mask: Bool = false) -> NSBezierPath {
        let pattern = NSBezierPath()
        for index in 0..<16 {
            let long = index.isMultiple(of: 2)
            let length: CGFloat = long ? 40 : 30
            let halfWidth: CGFloat = long ? 3.4 : 2.1
            let spoke = NSBezierPath()
            // Narrow roots converge at the hub; straight tapered sides end in a round cap.
            spoke.move(to: CGPoint(x: -0.35, y: mask ? -11 : -1.5))
            spoke.line(to: CGPoint(x: -halfWidth, y: -(length - halfWidth)))
            spoke.curve(to: CGPoint(x: 0, y: -length),
                        controlPoint1: CGPoint(x: -halfWidth, y: -length),
                        controlPoint2: CGPoint(x: -halfWidth * 0.55, y: -length))
            spoke.curve(to: CGPoint(x: halfWidth, y: -(length - halfWidth)),
                        controlPoint1: CGPoint(x: halfWidth * 0.55, y: -length),
                        controlPoint2: CGPoint(x: halfWidth, y: -length))
            spoke.line(to: CGPoint(x: 0.35, y: mask ? -11 : -1.5))
            spoke.close()
            let transform = AffineTransform(rotationByDegrees: CGFloat(index) * 22.5 + rotation)
            spoke.transform(using: transform)
            pattern.append(spoke)
            if mask {
                // Staggered inner apertures break the hub into tiny illuminated slivers.
                for (radius, offset, width, height): (CGFloat, CGFloat, CGFloat, CGFloat) in [
                    (7.5, 8, 1.6, 3.2), (3.5, -4, 1.0, 1.8)
                ] {
                    let slit = NSBezierPath(ovalIn: NSRect(x: -width / 2,
                                                        y: -radius - height / 2,
                                                        width: width, height: height))
                    slit.transform(using: AffineTransform(rotationByDegrees: CGFloat(index) * 22.5 + offset))
                    pattern.append(slit)
                }
            }
        }
        return pattern
    }
}

final class ClockView: NSView {
    var date = Date()
    var displayOnly = UserDefaults.standard.bool(forKey: "displayOnly")
    var brightness: CGFloat = UserDefaults.standard.object(forKey: "dim") as? Bool == true ? 0.48 : 1
    override var isFlipped: Bool { true }
    override var mouseDownCanMoveWindow: Bool { true }
    let orange = NSColor(srgbRed: 1, green: 0.22, blue: 0.045, alpha: 1)
    func shape(_ rect: NSRect, radius: CGFloat, color: NSColor) {
        color.setFill(); NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
    }
    func polygon(_ points: [CGPoint]) -> NSBezierPath {
        let p = NSBezierPath(); p.move(to: points[0]); points.dropFirst().forEach { p.line(to: $0) }; p.close(); return p
    }
    func light(_ path: NSBezierPath, active: Bool = true) {
        NSGraphicsContext.saveGraphicsState()
        if active {
            let glow = NSShadow(); glow.shadowColor = orange.withAlphaComponent(0.65 * brightness); glow.shadowBlurRadius = 9; glow.shadowOffset = .zero; glow.set()
            orange.withAlphaComponent(brightness).setFill(); path.fill()
            NSShadow().set()
            NSColor(srgbRed: 1, green: 0.38, blue: 0.12, alpha: 0.5 * brightness).setStroke(); path.lineWidth = 0.6; path.stroke()
        } else { NSColor(srgbRed: 0.13, green: 0.065, blue: 0.045, alpha: 0.24).setFill(); path.fill() }
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
        // Enlarge the whole ornament around its centre and lift it slightly.
        let ornamentTransform = NSAffineTransform()
        ornamentTransform.translateX(by: 645, yBy: 204)
        ornamentTransform.scale(by: 1.1)
        ornamentTransform.translateX(by: -645, yBy: -212)
        ornamentTransform.concat()
        let state = FlowerState(seconds: seconds)
        NSGraphicsContext.saveGraphicsState()
        let centre = NSAffineTransform()
        centre.translateX(by: 645, yBy: 212)
        centre.concat()
        // A stationary aperture reveals only the overlapping part of the rotating disc.
        // Both patterns remain rigid: no petal scaling, morphing, or opacity animation.
        FlowerState.pattern(mask: true).addClip()
        light(FlowerState.pattern(rotation: state.discAngle))
        NSGraphicsContext.restoreGraphicsState()
        let dot = CGPoint(x: 645 + 50 * sin(state.dotAngle), y: 212 - 50 * cos(state.dotAngle))
        light(NSBezierPath(ovalIn: NSRect(x: dot.x - 2.2, y: dot.y - 2.2, width: 4.4, height: 4.4)))
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor(srgbRed: 0.075,green: 0.075,blue: 0.07,alpha: 1).setFill(); bounds.fill()
        NSGraphicsContext.saveGraphicsState()
        let scale = min(bounds.width / 800, bounds.height / (displayOnly ? 405 : 570))
        let transform = NSAffineTransform(); transform.translateX(by: (bounds.width - 800 * scale)/2, yBy: (bounds.height - (displayOnly ? 405 : 570)*scale)/2)
        transform.scale(by: scale); transform.concat()
        if !displayOnly {
            shape(NSRect(x: 235,y: 478,width: 330,height: 48),radius: 7,color: .black)
            let stem = polygon([CGPoint(x: 326,y: 383),CGPoint(x: 474,y: 383),CGPoint(x: 491,y: 504),CGPoint(x: 309,y: 504)])
            NSGradient(starting: NSColor(white: 0.91,alpha: 1), ending: NSColor(white: 0.64,alpha: 1))!.draw(in: stem,angle: 0)
            shape(NSRect(x: 228,y: 509,width: 344,height: 9),radius: 3,color: NSColor(white: 0.16,alpha: 1))
        }
        let body = NSBezierPath(roundedRect: NSRect(x: 24,y: 24,width: 752,height: 386),xRadius: 48,yRadius: 48)
        NSGradient(starting: NSColor(srgbRed: 0.96,green: 0.95,blue: 0.9,alpha: 1),ending: NSColor(srgbRed: 0.71,green: 0.71,blue: 0.66,alpha: 1))!.draw(in: body,angle: 90)
        shape(NSRect(x: 42,y: 37,width: 716,height: 327),radius: 31,color: NSColor(white: 0.025,alpha: 1))
        let glass = NSBezierPath(roundedRect: NSRect(x: 49,y: 43,width: 702,height: 312),xRadius: 26,yRadius: 26)
        NSGradient(starting: NSColor(srgbRed: 0.065,green: 0.061,blue: 0.047,alpha: 1),ending: NSColor(white: 0.012,alpha: 1))!.draw(in: glass,angle: 90)
        let time = ClockTime(date)
        let d = time.digits
        digit(d[0],x: 88,y: 102,small: true); digit(d[1],x: 153,y: 102)
        digit(d[2],x: 365,y: 102); digit(d[3],x: 477,y: 102)
        for y: CGFloat in [164,234] { light(NSBezierPath(rect: NSRect(x: 290,y: y,width: 12,height: 7))) }
        NSGraphicsContext.saveGraphicsState()
        let indicatorGlow = NSShadow()
        indicatorGlow.shadowColor = orange.withAlphaComponent(0.45 * brightness)
        indicatorGlow.shadowBlurRadius = 5
        indicatorGlow.shadowOffset = .zero
        indicatorGlow.set()
        let indicator = (time.isPM ? "PM" : "AM") as NSString
        let indicatorFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .medium)
        let indicatorAttributes: [NSAttributedString.Key: Any] = [
            .font: indicatorFont, .foregroundColor: orange.withAlphaComponent(brightness)]
        let indicatorSize = indicator.size(withAttributes: indicatorAttributes)
        // Centre beneath the flower; align the capital glyphs with the digit bottoms.
        indicator.draw(at: CGPoint(x: 645 - indicatorSize.width / 2,
                                   y: 291 - indicatorFont.ascender),
                       withAttributes: indicatorAttributes)
        NSGraphicsContext.restoreGraphicsState()
        flower(seconds: date.timeIntervalSince1970)
        NSGraphicsContext.saveGraphicsState(); glass.addClip()
        NSColor(white: 1,alpha: 0.025).setFill()
        polygon([CGPoint(x: 49,y: 43),CGPoint(x: 751,y: 43),CGPoint(x: 751,y: 67),CGPoint(x: 49,y: 150)]).fill()
        NSGraphicsContext.restoreGraphicsState()
        shape(NSRect(x: 568,y: 371,width: 118,height: 26),radius: 1,color: NSColor(srgbRed: 0.19,green: 0.13,blue: 0.10,alpha: 1))
        ("LUMITIME" as NSString).draw(at: CGPoint(x: 576,y: 373),withAttributes: [.font: NSFont(name: "HelveticaNeue-CondensedBold",size: 21) ?? NSFont.boldSystemFont(ofSize: 19),.foregroundColor: NSColor(white: 0.94,alpha: 1)])
        NSGraphicsContext.restoreGraphicsState()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let clock = ClockView()
    var timer: Timer?
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        NSApp.mainMenu = menu; NSApp.activate(ignoringOtherApps: true)
    }
    @objc func update() { clock.date = Date(); clock.needsDisplay = true; clock.setAccessibilityValue(clock.date.formatted(date: .omitted,time: .standard)) }
    @objc func onTop(_ sender: NSMenuItem) { sender.state = sender.state == .on ? .off : .on; window.level = sender.state == .on ? .floating : .normal; UserDefaults.standard.set(sender.state == .on,forKey: "onTop") }
    @objc func displayOnly(_ sender: NSMenuItem) { clock.displayOnly.toggle(); sender.state = clock.displayOnly ? .on : .off; UserDefaults.standard.set(clock.displayOnly,forKey: "displayOnly"); clock.needsDisplay = true }
    @objc func dim(_ sender: NSMenuItem) { sender.state = sender.state == .on ? .off : .on; clock.brightness = sender.state == .on ? 0.48 : 1; UserDefaults.standard.set(sender.state == .on,forKey: "dim"); clock.needsDisplay = true }
    @objc func fullScreen() { window.toggleFullScreen(nil) }
    @objc func about() { NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "Lumitime",.applicationVersion: "1.0",.credits: NSAttributedString(string: "A native tribute to the Tamura Lumitime KT-10B.\nCustom orange shutter digits and a flower seconds display.\nBlooming petals and a clockwise seconds dot, based on the video reference.")]) }
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
    let mask = FlowerState.pattern()
    let aligned = FlowerState.pattern(rotation: 45)
    let offset = FlowerState.pattern(rotation: 11.25)
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
